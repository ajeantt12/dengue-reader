# DengueReader

A Flutter mobile app that photographs dengue rapid diagnostic test (RDT) plates, analyses reagent dot colour saturation, and returns a **Positive / Negative / Invalid** result — designed for rural use in India with non-technical lab assistants as users.

## How it works

1. The user aligns the test cassette in the camera viewfinder.
2. The app photographs the plate after a short countdown.
3. A colour-correction step normalises the image against a known-colour reference patch on the cassette.
4. Each reagent dot in the 3 × 2 grid is sampled for HSV saturation.
5. A result is calculated: dots with saturation > 0.35 are reactive (positive).
6. Results are saved locally and viewable in a history log.

## Tech stack

| Concern | Library |
|---|---|
| UI framework | Flutter 3.22 / Dart |
| State management | Riverpod 2 (riverpod_generator) |
| Navigation | go_router |
| Image processing | `image` (pure Dart) |
| Local storage | Hive |
| Theme | Material 3 via flex_color_scheme |

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.22
- Android SDK (API 21+) or Xcode for iOS
- A physical device is recommended for camera testing

### Install & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

## Project structure

```
lib/
  app.dart                  # App root, Hive init, ProviderScope
  main.dart
  core/
    constants/              # Thresholds, dot positions, app-wide constants
    exceptions/
    router/                 # go_router configuration
    theme/                  # flex_color_scheme setup
  features/
    capture/                # Camera screen, viewfinder overlay, camera provider
    analysis/               # Colour correction, dot detection, result calculator
    result/                 # Result display screen
    history/                # Saved results list
  shared/
    models/                 # Hive models (TestResult, DotReading)
    widgets/
```

## Status

- [x] Camera capture (countdown, haptic feedback, torch toggle)
- [x] Colour correction (reference-patch RGB normalisation)
- [x] Dot detector (HSV sampling, 3 × 2 grid)
- [x] Result calculator (control check → Positive / Negative / Invalid + confidence)
- [x] Analysis provider (full pipeline, auto-persist to Hive)
- [x] Result screen (result card, dot grid, confidence bar)
- [x] History screen (list, delete, clear all, re-view)
- [ ] Lighting guidance UI
- [ ] Error states (plate not found, poor image quality)
- [ ] QA on physical device

## Licence

Private / not yet licensed.
