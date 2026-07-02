# Research assets — colour calibration dataset

This folder holds the raw material for calibrating DengueReader's colour
correction and result-judging logic against real test plates photographed by
the research team.

```
research/
├── README.md                     ← this file
├── samples/                      ← test-plate photos (the calibration dataset)
│   ├── DRNNN.jpeg                ← renamed, stable-ID sample images
│   └── calibration_index.csv     ← identification matrix (one row per image)
└── design/
    ├── plates/                   ← plate physical design files (CAD/PDF/PNG)
    └── colour_strips/            ← printed colour-strip reference (RGB + CMYK PDFs)
```

## Naming workflow

Sample images get a **stable, opaque ID** — `DR` + 3-digit zero-padded number
(`DR001`, `DR002`, …). The ID carries no meaning on its own; **all metadata
lives in `calibration_index.csv`**, keyed by `id`. This keeps filenames stable
even if our judgement about an image's quality or contents changes.

### Adding new images from the research team
1. Drop the new files (any name) into `samples/`.
2. Assign the next free `DRNNN` IDs and rename.
3. Before assigning, compute the `md5` and check it against the `md5` column in
   `calibration_index.csv` — WhatsApp re-sends create exact duplicates
   (e.g. DR005/DR006). Skip files whose md5 already exists.
4. Add one row per new image to `calibration_index.csv`.

Multi-plate frames (`plate_count > 1`) are split into `DRNNNa`, `DRNNNb`, …
crops before they enter the per-plate calibration step.

## Identification matrix (`calibration_index.csv`)

| column | meaning |
|---|---|
| `id` / `filename` | stable ID and current file |
| `old_filename` / `md5` | provenance + duplicate detection |
| `capture_date` / `device` | from filename / EXIF |
| `plate_count` | 1 = single plate, >1 = needs splitting |
| `orientation` / `framing` | layout of the shot |
| `positive_wells` / `negative_wells` | **ground-truth labels** — which wells are reactive |
| `marking_scheme` | hand annotations present: `+` positive, `×` negative, arrows point to reactive wells |
| `reference_strip` | where the CMYK colour strip sits in frame |
| `quality_grade` | **A** ready / **B** usable / **C** needs work (split/crop) / **X** reject |
| `usable_for_calibration` | yes / no / split-first |
| `issues` / `notes` | free text |

### Quality grades at a glance
- **A (gold)** — DR005, DR008, DR009, DR010: sharp close-ups, single plate,
  colour strip clear, even light. DR005 is the reference exemplar; DR010 is a
  valuable *faint-positive* case for threshold tuning.
- **B (usable)** — DR002, DR003, DR004, DR011: full plate but small/tilted/soft.
- **C (split first)** — DR007, DR013: three plates per frame.
- **X (reject)** — DR001 (truncated), DR006 (duplicate), DR012 (rig photo).

## Ground-truth result convention
Each plate has a **3-well reactive line** dosed with positive reagent (turns
**yellow**) plus negative wells (stay **clear**). Depending on plate orientation
the positive line reads as the **top row** (portrait close-ups) or the
**left column** (landscape). The `positive_wells` column records this per image.

## Reference colour strip
The strip is a printed **7-patch CMYK chart**: black, yellow, magenta, cyan
(top) and grey, white, orange (bottom). Source artwork:
`design/colour_strips/colour_stripesRGB.pdf` and `…CMYK.pdf`. These known
patch values are the targets for the colour-correction transform.

## ⚠️ Open discrepancy — grid geometry
`CLAUDE.md` and `app_constants.dart` describe a **3×2 (6-dot)** grid, but the
plate design (`design/plates/plate01-design.png`, 3.4 × 7.1 cm) and every photo
show an **8×3 (24-well)** layout with a 3-well reactive line. **This must be
reconciled before dot-position calibration** — the dot coordinates and the
`S > 0.35` threshold both depend on it.
