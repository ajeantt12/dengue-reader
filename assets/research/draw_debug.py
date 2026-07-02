"""
draw_debug.py
-------------
Draws the sampled well centres and strip patch centres on each annotated image.
Saves to samples/debug/DRNNN_debug.jpeg so you can open them and check
whether the dots land where they should.

  Positive wells  -> green circle
  Negative wells  -> red circle
  Strip patches   -> yellow circle with patch-name label

Usage:
  py -3 assets/research/draw_debug.py
"""

import json
import colorsys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SAMPLES_DIR = Path(__file__).parent / "samples"
ANNO_DIR    = SAMPLES_DIR / "annotations"
DEBUG_DIR   = SAMPLES_DIR / "debug"
DEBUG_DIR.mkdir(exist_ok=True)

DISC_RADIUS   = 12
MARKER_RADIUS = 18   # slightly larger than disc so you can see the ring

PATCH_NAMES = {
    (0, 0): "K",  (0, 1): "Y",  (0, 2): "M",  (0, 3): "C",
    (1, 0): "grey", (1, 1): "white", (1, 3): "orange",
}


def lerp2d(tl, tr, br, bl, u, v):
    top    = (tl[0] + u*(tr[0]-tl[0]),  tl[1] + u*(tr[1]-tl[1]))
    bottom = (bl[0] + u*(br[0]-bl[0]),  bl[1] + u*(br[1]-bl[1]))
    return (
        top[0] + v*(bottom[0]-top[0]),
        top[1] + v*(bottom[1]-top[1]),
    )


def draw_image(anno_path):
    anno   = json.loads(anno_path.read_text())
    img_path = SAMPLES_DIR / f"{anno['id']}.jpeg"
    img    = Image.open(img_path).convert("RGB")
    draw   = ImageDraw.Draw(img)
    W, H   = img.size

    pc = anno["plate_corners_px"]
    sc = anno["strip_corners_px"]
    tl_p = pc["tl"]; tr_p = pc["tr"]; br_p = pc["br"]; bl_p = pc["bl"]
    tl_s = sc["tl"]; tr_s = sc["tr"]; br_s = sc["br"]; bl_s = sc["bl"]

    rows = anno["visible_grid"]["rows"]
    cols = anno["visible_grid"]["cols"]

    # Draw plate bounding box
    for a, b in [(tl_p,tr_p),(tr_p,br_p),(br_p,bl_p),(bl_p,tl_p)]:
        draw.line([a[0],a[1],b[0],b[1]], fill=(0,200,255), width=3)

    # Draw strip bounding box
    for a, b in [(tl_s,tr_s),(tr_s,br_s),(br_s,bl_s),(bl_s,tl_s)]:
        draw.line([a[0],a[1],b[0],b[1]], fill=(255,200,0), width=3)

    # Draw well markers
    for r in range(rows):
        for c in range(cols):
            u = (c + 0.5) / cols
            v = (r + 0.5) / rows
            cx, cy = lerp2d(tl_p, tr_p, br_p, bl_p, u, v)
            cell_id = f"R{r+1}C{c+1}"
            is_pos  = cell_id in anno["labels"]["positive_cells"]
            colour  = (0, 255, 0) if is_pos else (255, 60, 60)
            r2 = MARKER_RADIUS
            draw.ellipse([cx-r2, cy-r2, cx+r2, cy+r2], outline=colour, width=3)
            draw.line([cx-4, cy, cx+4, cy], fill=colour, width=2)
            draw.line([cx, cy-4, cx, cy+4], fill=colour, width=2)
            draw.text((cx + r2 + 2, cy - 8), cell_id, fill=colour)

    # Draw strip patch markers
    strip_rows_n = anno["strip_layout"]["rows"]
    strip_cols_n = anno["strip_layout"]["cols"]
    for (pr, pc_idx), name in PATCH_NAMES.items():
        u = (pc_idx + 0.5) / strip_cols_n
        v = (pr    + 0.5) / strip_rows_n
        cx, cy = lerp2d(tl_s, tr_s, br_s, bl_s, u, v)
        r2 = MARKER_RADIUS
        draw.ellipse([cx-r2, cy-r2, cx+r2, cy+r2], outline=(255,255,0), width=3)
        draw.text((cx + r2 + 2, cy - 8), name, fill=(255,255,0))

    out_path = DEBUG_DIR / f"{anno['id']}_debug.jpeg"
    img.save(out_path, quality=92)
    print(f"Wrote {out_path}")


for af in sorted(ANNO_DIR.glob("DR*.json")):
    draw_image(af)

print("\nOpen the images in samples/debug/ to verify dot placement.")
print("  Green ring  = positive well (should land on yellow dot)")
print("  Red ring    = negative well (should land on clear dome)")
print("  Yellow ring = colour strip patch (should land on the correct patch)")
