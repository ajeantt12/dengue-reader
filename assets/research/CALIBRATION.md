# Colour calibration plan

Two goals, in order:
1. **Accurate hue** of a correct (positive) result.
2. **Accurate intensity** for that hue (how saturated = how reactive).

Pipeline: **locate → colour-correct → judge**.

---

## 1. Plate geometry (decided)

- **Canonical grid: 8 rows × 3 columns = 24 wells.** Source of truth:
  `design/plates/plate01-design.png` (3.4 × 7.1 cm).
- In a full-plate photo the **colour strip is laid over the middle 2 rows**, so
  only **6 rows × 3 = 18 wells are readable**. Close-up shots show even fewer
  rows (often just the 3-well reactive line) — that's fine, we annotate what's
  visible per image.
- **Reactive line = positive.** It reads as the **top row** (portrait close-ups)
  or the **left column** (landscape), depending on orientation. Everything else
  is negative. Ground truth per image is in `samples/calibration_index.csv`
  (`positive_wells` / `negative_wells`).

> Migration note: `lib/core/constants/app_constants.dart` still encodes the old
> 3×2 / 6-dot grid and a single grey reference patch. That gets rewritten to
> the 8×3 model + 7-patch strip as a separate, deliberate step (it would break
> the current detector's compile, so it is not done in the data-setup pass).

## 2. Well location — 8-corner annotation (no detection code)

These images were shot **outside the app**, so wells don't sit at fixed
coordinates. Rather than build plate detection now, we annotate 8 points and
interpolate. (Once in-app capture exists, images auto-align and the 8 corners
become a fixed frame — the same sampling math still runs.)

Per usable image we store a sidecar `annotations/DRNNN.json`:

```json
{
  "id": "DR005",
  "image_size_px": [width, height],
  "orientation": "portrait",
  "reactive_line": "row1",
  "visible_grid": { "rows": 3, "cols": 3 },
  "plate_corners_px": { "tl": [x, y], "tr": [x, y], "br": [x, y], "bl": [x, y] },
  "strip_corners_px": { "tl": [x, y], "tr": [x, y], "br": [x, y], "bl": [x, y] },
  "strip_layout": {
    "rows": 2, "cols": 4,
    "patches": ["K", "Y", "M", "C", "grey", "white", "orange"]
  },
  "labels": {
    "positive_cells": ["R1C1", "R1C2", "R1C3"],
    "negative_cells": ["R2C1", "R2C2", "R2C3", "R3C1", "R3C2", "R3C3"]
  },
  "correction_method": "cmyk",
  "notes": ""
}
```

- `plate_corners_px` are the 4 corners of the **visible well-block**. Well
  centres = bilinear interpolation across `visible_grid.rows × cols`.
- `strip_corners_px` are the 4 corners of the colour strip. Patch centres =
  bilinear interpolation across `strip_layout.rows × cols` (the 7 patches fill a
  4-col × 2-row block; bottom row uses 3 of 4 cells).
- Sample a small disc (e.g. r = 8 px scaled) at each centre and average.

Annotation order of work: gold set first — **DR005, DR008, DR009, DR010**
(DR010 is the faint-positive case, key for the intensity threshold), then the
B-grade singles, then split the multi-plate frames (DR007, DR013).

## 3. Colour correction — selectable method, recorded per analysis

The strip is a **7-patch CMYK chart**: `K, Y, M, C` (top row) + `grey, white,
orange` (bottom). Source artwork in `design/colour_strips/`.

```
enum CorrectionMethod { cmyk, greyscale }   // DEFAULT: cmyk
```

- **cmyk (default)** — fit a correction matrix from all 7 measured-vs-known
  patches. Best hue accuracy across the gamut.
- **greyscale** — use only the neutral patches (`K`, `grey`, `white`) for
  white-balance + exposure normalization. Simpler; weaker on hue.

Every analysis **records which method it used** (`correction_method` on the
record). Across testing we compare the two on identical wells and decide whether
CMYK is worth keeping or greyscale suffices.

Known patch reference values (RGB targets) live in `reference_patches.csv`
(to be measured from the printed strip / derived from the source PDFs).

## 4. Result judging matrix (after correction)

For each corrected well, compute HSV. A well is **reactive** when its hue falls
in the positive band **and** saturation/intensity clears a threshold. The
positive hue band and the intensity threshold are exactly what this calibration
fits — using the labelled positives (yellow wells) vs. negatives (clear wells)
across the gold set, including DR010's faint positives to place the lower bound.

Output per plate: Positive / Negative / Invalid + confidence (control-line
sanity check first).
