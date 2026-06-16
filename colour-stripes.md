# Colour Matching Strips — Printing & Calibration Guide

## Purpose

The colour matching strip is a small printed card placed alongside the dengue test plate when photographing it. It contains two reference patches with known, pre-measured colours. The app reads these patches to correct for the camera's white balance and ambient lighting, so that dot saturation readings are consistent across phones, times of day, and locations.

---

## What to print

Print **two colour patches** side by side on the card, plus a neutral grey patch used as the correction anchor.

### Patch 1 — Reactive Reference (Yellow)

Represents a **strongly reactive dot** at the upper end of the expected range.

| Property | Value |
|----------|-------|
| Colour name | Cadmium Yellow |
| sRGB | R 255, G 213, B 0 |
| Hex | `#FFD500` |
| CMYK (for print) | C 0, M 16, Y 100, K 0 |
| HSV | H 50°, S 1.0, V 1.0 |
| Expected saturation after correction | 0.90–1.0 |

### Patch 2 — Non-Reactive Reference (Near-White)

Represents a **clear / non-reactive dot**.

| Property | Value |
|----------|-------|
| Colour name | Near-White |
| sRGB | R 240, G 238, B 232 |
| Hex | `#F0EEE8` |
| CMYK (for print) | C 0, M 1, Y 3, K 6 |
| HSV | H 45°, S 0.03, V 0.94 |
| Expected saturation after correction | 0.02–0.08 |

### Patch 3 — Neutral Grey (Correction Anchor)

This is the patch the `ColourCorrectionService` reads. It must match the constant in the code exactly.

| Property | Value |
|----------|-------|
| Colour name | Mid Grey |
| sRGB | R 200, G 200, B 200 |
| Hex | `#C8C8C8` |
| CMYK (for print) | C 0, M 0, Y 0, K 22 |
| HSV | H 0°, S 0.0, V 0.78 |
| Code constant | `AppConstants.referenceKnownRgb = [200, 200, 200]` |

### Patch 4–7 — CMYK Diagnostic Stripe

A row of four pure ink patches printed below the three functional patches. **The app does not read these** — they exist so a batch manager can photograph the strip under a standard light and immediately identify which ink channel has drifted when a batch fails validation.

| Patch | Name | sRGB | Hex | CMYK |
|-------|------|------|-----|------|
| C | Process Cyan | R 0, G 174, B 239 | `#00AEEF` | C 100, M 0, Y 0, K 0 |
| M | Process Magenta | R 236, G 0, B 140 | `#EC008C` | C 0, M 100, Y 0, K 0 |
| Y | Process Yellow | R 255, G 242, B 0 | `#FFF200` | C 0, M 0, Y 100, K 0 |
| K | Process Black | R 35, G 31, B 32 | `#231F20` | C 0, M 0, Y 0, K 100 |

Print each at **20 × 20 mm**, 100% ink density, no screen tint.

**How to use for diagnosis:**

Photograph the full card under a neutral daylight bulb (5500 K). If the reactive yellow patch (#FFD500) is reading orange in the app, compare the printed C and M patches: if M looks pinkish-red instead of true magenta, the printer has excess magenta ink bleeding into yellow — the fix is to reduce M density or recalibrate the printer profile, not to change `referenceKnownRgb`.

| Symptom on reactive dot | Suspect channel | Diagnostic |
|-------------------------|-----------------|------------|
| Yellow reads orange | M too high | M patch looks red-shifted |
| Yellow reads green-yellow | C bleeding into Y | C patch looks teal, not pure cyan |
| Grey patch too warm | K has brown cast | K patch looks brownish |
| All patches too dark | Overall ink density too high | All patches under-saturated vs spec |

---

## Card layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  [  Yellow  ]  [ Near-White ]  [   Grey   ]                          │
│   32 × 32 mm    32 × 32 mm     32 × 32 mm   ← app reads grey only   │
│    #FFD500        #F0EEE8       #C8C8C8                              │
│                                                                      │
│  [   C   ]  [   M   ]  [   Y   ]  [   K   ]                         │
│  20 × 20 mm  20 × 20 mm  20 × 20 mm  20 × 20 mm  ← print QC only   │
│  #00AEEF    #EC008C    #FFF200    #231F20                            │
└──────────────────────────────────────────────────────────────────────┘
```

- Print on **matte coated paper**, 200–300 gsm. Glossy paper introduces specular highlights that skew the RGB reading.
- Use a **colour-calibrated inkjet** or send to a commercial print house. Home laser printers shift yellow significantly.
- **Laminate with matte laminate only** — gloss laminate reintroduces specular glare.
- Cut each card to roughly 120 × 65 mm and attach it to the top-right corner of the test plate tray with the grey patch in the corner position expected by the app.

---

## Where the grey patch must sit in the photo

The app crops the grey patch using these constants in `app_constants.dart`:

```dart
static const double referencePatchX    = 0.80;  // 80% from left edge
static const double referencePatchY    = 0.05;  // 5% from top edge
static const double referencePatchSize = 0.08;  // 8% of image width
```

When composing the photo, the grey patch on the card must fall in the **top-right ~8% × 8% square of the camera frame**. Place the card so the grey square sits there before freezing the composition.

---

## How calibration works (service walkthrough)

`ColourCorrectionService.applyCorrection()` does three things:

1. **Crops** the grey patch region from the image using the constants above.
2. **Averages** the RGB of all pixels in that crop → `(avgR, avgG, avgB)`.
3. **Computes per-channel multipliers**: `corrR = 200 / avgR`, `corrG = 200 / avgG`, `corrB = 200 / avgB`.
4. **Multiplies every pixel** in the full image by these factors, clamped to 0–255.

After correction, any pixel that was the printed grey colour will read as exactly RGB (200, 200, 200), and the yellow reactive patches will read close to their true sRGB values.

---

## How to calibrate a new print batch

Each time you print a new batch of strips, measure the actual printed colours with a **spectrophotometer** (e.g. X-Rite i1Display) or a calibrated phone camera with a colour checker app. Then update the constants as needed.

### Step 1 — Measure the printed grey patch

Photograph the strip under your standard lighting (or use the spectrophotometer). Record the measured average RGB of the grey patch — for example `(188, 191, 195)` if your printer is slightly cool.

### Step 2 — Update `referenceKnownRgb`

In `lib/core/constants/app_constants.dart`, set:

```dart
static const List<int> referenceKnownRgb = [188, 191, 195]; // your measured values
```

This tells the correction service what the grey patch *should* read after correction, anchoring the whole pipeline to the real printed colour.

### Step 3 — Verify with the yellow patch

After applying the correction, photograph the strip alone and log the corrected RGB of the yellow patch. It should be within ±15 counts of R 255, G 213, B 0. If it is outside that range, your print is too far from spec — reprint or use a different paper/ink combination.

### Step 4 — Re-verify the saturation threshold

Run the app against a known-positive and known-negative plate. The reactive dots should read saturation > 0.35 and the non-reactive dots < 0.15. The gap between those bands gives you headroom. If bands overlap, consider adjusting `saturationThreshold` in `app_constants.dart` (currently `0.35`) to a value that cleanly separates them.

---

## Quick reference — expected HSV values after correction

| Dot state | Hue | Saturation | Value (brightness) |
|-----------|-----|------------|-------------------|
| Reactive (positive) | 50–65° | 0.60–1.0 | 0.80–0.95 |
| Non-reactive (negative) | any | 0.02–0.10 | 0.85–0.95 |
| Decision threshold | — | **0.35** | — |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| All dots read as positive | Grey patch too dark on print → correction overcorrects | Reprint with higher paper brightness; or lower `referenceKnownRgb` values |
| All dots read as negative | Grey patch too light → correction undercorrects | Reprint with denser ink; or raise `referenceKnownRgb` values |
| Saturation values erratic between shots | Gloss laminate causing specular glare | Switch to matte laminate |
| Yellow patch reads orange after correction | CMYK yellow shifted toward red by laser printer | Use inkjet with ICC profile, or adjust CMYK to C0 M10 Y95 K0 |
