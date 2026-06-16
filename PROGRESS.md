# DengueReader — Development Progress

---

## Phase 1 — Initial commit & basic demo UI

**Status: Complete**

### What was built

- Flutter project scaffolded with feature-first folder structure (`lib/features/`)
- Riverpod 2 state management wired up with code generation (`@riverpod`, `build_runner`)
- `go_router` navigation with named routes for all four screens
- Material 3 theme via `flex_color_scheme`; all colours in `app_colors.dart`

**Camera & capture**
- [x] `CameraProvider` — initialises `camera` plugin, exposes stream
- [x] Countdown timer (3 s) with haptic feedback before capture
- [x] Torch toggle button
- [x] `ViewfinderOverlay` — guide frame drawn over the camera preview

**Analysis pipeline**
- [x] `ColourCorrectionService` — crops the grey reference patch (top-right 8 % of frame), computes per-channel RGB multipliers, applies pixel-wise correction
- [x] `DotDetectorService` — samples a circular region around each of the 6 dot centres, converts average RGB → HSV, returns a `DotReading` per dot
- [x] `ResultCalculator` — control-dot check, applies saturation threshold (> 0.35 = reactive), returns `Positive / Negative / Invalid` + confidence score
- [x] `AnalysisProvider` — orchestrates the full pipeline and auto-persists result to Hive

**Screens**
- [x] Capture screen — countdown, viewfinder overlay, torch toggle
- [x] Analysis screen — processing animation
- [x] Result screen — result card, 3 × 2 dot grid display, confidence bar
- [x] History screen — list of saved results, delete / clear-all, tap to re-view

**Storage**
- [x] Hive models: `TestResult` (typeId 0), `DotReading` (typeId 1)
- [x] History provider — opens Hive box, exposes list, handles add/delete

**Demo mode**
- [x] `DemoService` — returns synthetic dot readings for UI testing without a physical plate

### Known gaps at end of Phase 1
- Dot grid position constants (`app_constants.dart`) are estimates — not yet validated against a real plate photo
- No lighting guidance shown to the user
- No graceful error UI for `PlateNotDetectedException` / `ImageTooDataarkException` / `ImageOverexposedException`

---

## Phase 2 — Colour calibration & strip testing

**Status: In progress**

The goal of this phase is to validate and tune the analysis pipeline against printed colour strips and a real dengue test plate. Every number the pipeline relies on — reference patch position, dot centre coordinates, saturation threshold — gets verified and adjusted here.

### 2a — Print & prepare the colour strip

- [ ] Print `colour_stripesRGB.pdf` on matte coated paper (200–300 gsm) using a colour-calibrated inkjet
  - Do **not** use a laser printer — laser yellow shifts significantly toward orange
  - Do **not** use gloss paper or gloss laminate — specular highlights corrupt the grey reading
- [ ] Verify printed patches visually against spec:
  - Yellow patch (`#FFD500`) — should look a saturated cadmium yellow, not orange or lime
  - Near-white patch (`#F0EEE8`) — should look almost white with the faintest warm tint
  - Grey patch (`#C8C8C8`) — should look a clean neutral mid-grey, no warm/cool cast
- [ ] Laminate with **matte laminate only** (if laminating)
- [ ] Cut to ~120 × 65 mm and confirm the grey patch sits in the top-right corner when placed on the tray

### 2b — Measure the printed grey patch

- [ ] Photograph the strip under your standard lighting (5 500 K daylight bulb or outdoors in open shade)
- [ ] Crop the grey patch area in any image editor and record the average RGB (e.g. use Photoshop eyedropper on a 10 × 10 px average sample, or use the app's debug log)
- [ ] If the measured RGB differs from `[200, 200, 200]` by more than ±10 in any channel, update `AppConstants.referenceKnownRgb` in `lib/core/constants/app_constants.dart`:

  ```dart
  static const List<int> referenceKnownRgb = [188, 191, 195]; // replace with measured values
  ```

### 2c — Verify grey-patch crop position

- [ ] Capture a test photo with the strip placed as described
- [ ] Add a temporary debug overlay to `ColourCorrectionService` that draws a red rectangle over the cropped patch region and saves the annotated image
- [ ] Confirm the red rectangle falls entirely within the printed grey square
- [ ] Adjust `referencePatchX`, `referencePatchY`, `referencePatchSize` in `app_constants.dart` if the crop misses

### 2d — Validate the colour correction output

- [ ] After `applyCorrection()` runs, log the corrected average RGB of the yellow patch
  - Expected: within ±15 counts of R 255, G 213, B 0
  - If yellow reads orange (R high, G low): M ink too high — see `colour-stripes.md` for diagnosis
  - If yellow reads lime (G high): C ink bleeding into Y
- [ ] Log the corrected average RGB of the near-white patch
  - Expected HSV saturation after correction: 0.02–0.08
- [ ] Log corrected grey patch — should read exactly `[200, 200, 200]` (or your `referenceKnownRgb` value)

### 2e — Calibrate dot positions on a real plate

- [ ] Photograph a real dengue test cassette (or a printed facsimile) in the viewfinder
- [ ] Open the captured image and manually measure each dot centre as a fraction of image width/height
- [ ] Compare measured positions against `AppConstants.dotCentres` in `app_constants.dart`
- [ ] Update `dotCentres` map and `dotRadius` if they differ by more than 2 % of image dimension:

  ```dart
  static const Map<String, List<double>> dotCentres = {
    'R1C1': [0.37, 0.30],   // update these
    ...
  };
  static const double dotRadius = 18.0;  // update if needed
  ```

- [ ] Re-run the detector on the test image and confirm all 6 dots are sampled correctly (no dot reads the surrounding plastic)

### 2f — Validate saturation threshold against real plates

- [ ] Run the pipeline on a **known-positive plate** (or the yellow patch as a proxy for a reactive dot)
  - Reactive dots must read saturation > 0.55 (well above the 0.35 threshold)
- [ ] Run on a **known-negative plate** (or the near-white patch as a proxy)
  - Non-reactive dots must read saturation < 0.10 (well below threshold)
- [ ] Record the saturation values in the table below:

  | Sample | Dot | Saturation | Pass? |
  |--------|-----|-----------|-------|
  | Known positive | R1C1 | — | — |
  | Known positive | R2C1 | — | — |
  | Known positive | R3C1 | — | — |
  | Known negative | R1C1 | — | — |
  | Known negative | R2C1 | — | — |
  | Known negative | R3C1 | — | — |

- [ ] If reactive and non-reactive bands overlap, adjust `AppConstants.saturationThreshold` to a value midway between the two bands

### 2g — Edge-case & lighting tests

- [ ] Test in bright direct sunlight — does the correction hold without the torch?
- [ ] Test in dim indoor light (< 100 lux) with torch on
- [ ] Test with the plate at a slight angle (up to ~10°) — do saturation readings remain stable?
- [ ] Test with a phone model different from the development phone — check for systematic white-balance offsets

### 2h — Implement lighting guidance UI

- [ ] Implement ambient brightness check in `LightingIndicator` widget (currently stub)
- [ ] Display warning banner if `CameraProvider.brightness < AppConstants.brightnessThreshold` (currently 0.3)
- [ ] Add sunlight recommendation text ("Move to open shade" / "Use torch indoors")

---

## Phase 3 — Error states & UX hardening

**Status: Not started**

- [ ] Error screen / inline error states for `PlateNotDetectedException`
- [ ] Error state for `ImageTooDataarkException` with retry prompt
- [ ] Error state for `ImageOverexposedException`
- [ ] Loading skeleton on history screen
- [ ] Haptic + audio feedback on result

---

## Phase 4 — QA on device

**Status: Not started**

- [ ] Install and smoke-test on Android (API 21, 28, 34)
- [ ] Install and smoke-test on iOS (14, 16, 17)
- [ ] Field test with non-technical users — observe capture flow
- [ ] Performance: confirm analysis pipeline completes in < 3 s on a mid-range Android (Snapdragon 6xx)
