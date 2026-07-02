"""
sample_colours.py
-----------------
Reads each DRNNN.json annotation, opens the matching DRNNN.jpeg, and samples:
  - The centre pixel disc of every visible well (averaged RGB → HSV)
  - The centre of every colour-strip patch (averaged RGB)

Writes results to:
  samples/colour_readings.csv   — one row per well/patch per image
  samples/patch_summary.csv     — measured strip patch RGBs per image (for correction matrix)

Usage:
  py -3 assets/research/sample_colours.py
"""

import json
import csv
import colorsys
import math
from pathlib import Path
from PIL import Image

SAMPLES_DIR = Path(__file__).parent / "samples"
ANNO_DIR    = SAMPLES_DIR / "annotations"
DISC_RADIUS = 12   # px — average this many pixels around each centre

# Strip patch layout: 4-col x 2-row; bottom row only has 3 patches in cols 1,2+3merged,4
PATCH_NAMES = {
    # (row, col) → patch name; 0-indexed within a 4-col grid
    (0, 0): "K",  (0, 1): "Y",  (0, 2): "M",  (0, 3): "C",
    # Bottom row: grey(col0), white spans cols 1-2 so centre at col1, orange at col3
    (1, 0): "grey", (1, 1): "white", (1, 3): "orange",
}

# Known target RGB values for each patch (from colour_stripesRGB.pdf source artwork).
# These are the "should be" values before any camera colour shift.
# TODO: verify against the PDF; update if the print uses different values.
PATCH_TARGETS_RGB = {
    "K":      (0,   0,   0),
    "Y":      (255, 255, 0),
    "M":      (255, 0,   255),
    "C":      (0,   255, 255),
    "grey":   (128, 128, 128),
    "white":  (255, 255, 255),
    "orange": (255, 165, 0),
}


def lerp2d(tl, tr, br, bl, u, v):
    """Bilinear interpolation. u=0→left, u=1→right; v=0→top, v=1→bottom."""
    top    = (tl[0] + u * (tr[0] - tl[0]),   tl[1] + u * (tr[1] - tl[1]))
    bottom = (bl[0] + u * (br[0] - bl[0]),   bl[1] + u * (br[1] - bl[1]))
    return (
        top[0] + v * (bottom[0] - top[0]),
        top[1] + v * (bottom[1] - top[1]),
    )


def sample_disc(pixels, cx, cy, radius, width, height):
    """Average RGB of all pixels within `radius` of (cx,cy)."""
    r2 = radius * radius
    rs, gs, bs, n = 0, 0, 0, 0
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx*dx + dy*dy > r2:
                continue
            x, y = int(cx + dx), int(cy + dy)
            if 0 <= x < width and 0 <= y < height:
                px = pixels[x, y]
                rs += px[0]; gs += px[1]; bs += px[2]; n += 1
    if n == 0:
        return (0, 0, 0)
    return (rs // n, gs // n, bs // n)


def rgb_to_hsv(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    return round(h * 360, 1), round(s, 4), round(v, 4)


def process_annotation(anno_path):
    anno = json.loads(anno_path.read_text())
    img_path = SAMPLES_DIR / anno["filename"] if "filename" in anno else SAMPLES_DIR / f"{anno['id']}.jpeg"
    if not img_path.exists():
        img_path = SAMPLES_DIR / f"{anno['id']}.jpeg"

    img    = Image.open(img_path).convert("RGB")
    pixels = img.load()
    W, H   = img.size

    pc = anno["plate_corners_px"]
    sc = anno["strip_corners_px"]
    tl_p = pc["tl"]; tr_p = pc["tr"]; br_p = pc["br"]; bl_p = pc["bl"]
    tl_s = sc["tl"]; tr_s = sc["tr"]; br_s = sc["br"]; bl_s = sc["bl"]

    rows = anno["visible_grid"]["rows"]
    cols = anno["visible_grid"]["cols"]

    well_rows = []
    patch_rows = []

    # --- Sample wells ---
    for r in range(rows):
        for c in range(cols):
            # Centre of well at grid cell (r, c); 0.5 offset to centre within cell
            u = (c + 0.5) / cols
            v = (r + 0.5) / rows
            cx, cy = lerp2d(tl_p, tr_p, br_p, bl_p, u, v)
            rgb = sample_disc(pixels, cx, cy, DISC_RADIUS, W, H)
            h, s, v_hsv = rgb_to_hsv(*rgb)
            cell_id = f"R{r+1}C{c+1}"
            is_positive = cell_id in anno["labels"]["positive_cells"]
            well_rows.append({
                "image_id":          anno["id"],
                "cell":              cell_id,
                "ground_truth":      "positive" if is_positive else "negative",
                "correction_method": anno["correction_method"],
                "centre_x":          round(cx, 1),
                "centre_y":          round(cy, 1),
                "R": rgb[0], "G": rgb[1], "B": rgb[2],
                "hue_deg":           h,
                "saturation":        s,
                "value":             v_hsv,
            })

    # --- Sample strip patches ---
    strip_rows_n = anno["strip_layout"]["rows"]
    strip_cols_n = anno["strip_layout"]["cols"]
    for (pr, pc_idx), name in PATCH_NAMES.items():
        u = (pc_idx + 0.5) / strip_cols_n
        v = (pr    + 0.5) / strip_rows_n
        cx, cy = lerp2d(tl_s, tr_s, br_s, bl_s, u, v)
        rgb = sample_disc(pixels, cx, cy, DISC_RADIUS, W, H)
        target = PATCH_TARGETS_RGB[name]
        patch_rows.append({
            "image_id":    anno["id"],
            "patch":       name,
            "centre_x":    round(cx, 1),
            "centre_y":    round(cy, 1),
            "measured_R":  rgb[0], "measured_G": rgb[1], "measured_B": rgb[2],
            "target_R":    target[0], "target_G": target[1], "target_B": target[2],
            "delta_R":     rgb[0] - target[0],
            "delta_G":     rgb[1] - target[1],
            "delta_B":     rgb[2] - target[2],
        })

    return well_rows, patch_rows


def main():
    all_wells  = []
    all_patches = []

    anno_files = sorted(ANNO_DIR.glob("DR*.json"))
    if not anno_files:
        print("No annotation files found in", ANNO_DIR)
        return

    for af in anno_files:
        print(f"Processing {af.name}...")
        wells, patches = process_annotation(af)
        all_wells.extend(wells)
        all_patches.extend(patches)
        print(f"  {len(wells)} wells, {len(patches)} patches")

    # Write colour_readings.csv
    readings_path = SAMPLES_DIR / "colour_readings.csv"
    well_fields = ["image_id","cell","ground_truth","correction_method",
                   "centre_x","centre_y","R","G","B","hue_deg","saturation","value"]
    with readings_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=well_fields)
        w.writeheader(); w.writerows(all_wells)
    print(f"\nWrote {readings_path}")

    # Write patch_summary.csv
    patch_path = SAMPLES_DIR / "patch_summary.csv"
    patch_fields = ["image_id","patch","centre_x","centre_y",
                    "measured_R","measured_G","measured_B",
                    "target_R","target_G","target_B",
                    "delta_R","delta_G","delta_B"]
    with patch_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=patch_fields)
        w.writeheader(); w.writerows(all_patches)
    print(f"Wrote {patch_path}")

    # Print a quick summary to screen
    print("\n=== WELL COLOUR SUMMARY ===")
    print(f"{'ID':<8} {'Cell':<6} {'Truth':<10} {'H°':>6} {'S':>7} {'V':>7}  RGB")
    print("-" * 65)
    for row in all_wells:
        print(f"{row['image_id']:<8} {row['cell']:<6} {row['ground_truth']:<10} "
              f"{row['hue_deg']:>6} {row['saturation']:>7} {row['value']:>7}  "
              f"({row['R']},{row['G']},{row['B']})")

    print("\n=== STRIP PATCH DELTAS (measured - target) ===")
    print(f"{'ID':<8} {'Patch':<8} {'dR':>6} {'dG':>6} {'dB':>6}   measured -> target")
    print("-" * 65)
    for row in all_patches:
        print(f"{row['image_id']:<8} {row['patch']:<8} "
              f"{row['delta_R']:>+6} {row['delta_G']:>+6} {row['delta_B']:>+6}   "
              f"({row['measured_R']},{row['measured_G']},{row['measured_B']}) -> "
              f"({row['target_R']},{row['target_G']},{row['target_B']})")


if __name__ == "__main__":
    main()
