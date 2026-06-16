# DengueReader — Claude Code Context

## What this app does
A Flutter mobile app that photographs dengue rapid test plates, 
analyses the colour saturation of reagent dots, and returns a 
Positive/Negative/Invalid result. Designed for rural use in India 
with non-technical lab assistants as users.

## Tech stack
- Flutter 3.22+ / Dart
- State: Riverpod (riverpod_generator)
- Navigation: go_router
- Image processing: `image` Dart package (pure Dart, no native)
- Local DB: Hive
- UI: Material 3 via flex_color_scheme

## Architecture
Feature-first folder structure under lib/features/.
Each feature has: presentation/, providers/, models/, services/.
Shared widgets go in lib/shared/widgets/.

## Key domain concepts
- TEST PLATE: A small transparent plastic cassette with a 3-row × 2-col grid of reagent dots
- REFERENCE PATCH: A known-colour printed square in the top-right corner of the plate — used for colour correction
- SATURATION READING: The HSV S-value of each dot after colour correction
- RESULT THRESHOLD: Dots with S > 0.35 are considered reactive (positive); defined in app_constants.dart

## Coding conventions
- All providers use @riverpod annotation (code generation)
- No StatefulWidgets — use ConsumerWidget + Riverpod
- Named routes only via go_router
- All colours via app_colors.dart, never hardcoded
- All dot position constants in app_constants.dart

## Current build status
- [x] Dependencies configured
- [x] Project structure scaffolded
- [x] Android permissions & SDK configured
- [x] Theme & Navigation skeleton implemented
- [x] Camera capture screen (countdown, haptic, torch toggle)
- [x] Colour correction service (reference-patch RGB correction)
- [x] Dot detector service (HSV sampling per dot, 3×2 grid)
- [x] Result calculator (control check → Positive/Negative/Invalid + confidence)
- [x] Analysis provider (full pipeline + auto-persist to Hive)
- [x] Result screen (result card, dot grid display, confidence bar)
- [x] History screen (list, delete, clear all, tap to re-view result)
- [x] Hive models (TestResult typeId 0, DotReading typeId 1)
- [ ] Lighting guidance UI (ambient detection, sunlight recommendation)
- [ ] Error states (plate not found, poor image quality)
- [ ] QA on emulator & physical device
