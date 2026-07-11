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
- TEST PLATE: A small transparent plastic cassette with a 3-row × 3-col grid of reagent dots.
  Row 1 = positive control, Row 2 = negative control, Row 3 = the actual sample being judged.
- COLOUR STRIP: A printed 7-patch CMYK card (below the plate in the shot) used for white balance —
  located by `PlateDetectorService`, which finds the whole plate content-based (no fixed positions).
- SATURATION READING: The HSV S-value of each well after white balance.
- RESULT THRESHOLD: Adaptive per-image — `ResultCalculator` derives a reactive threshold from the
  Row 1/Row 2 control anchors rather than a fixed global cutoff; see `agentrunbook.md`.

## Coding conventions
- All providers use @riverpod annotation (code generation)
- No StatefulWidgets — use ConsumerWidget + Riverpod
- Named routes only via go_router
- All colours via app_colors.dart, never hardcoded
- All dot position constants in app_constants.dart

## Agent workflow — required reading
- [handoff.md](handoff.md) — cross-tool project journal (this project is worked on from multiple apps/models with no shared session history). Has a PINNED current-state block (always overwritten) plus an append-only, newest-first session log below it. Read PINNED + the last couple of log entries before starting work.
- [agentrunbook.md](agentrunbook.md) — durable rules, footguns, and technical conventions learned while working in this repo (not session narrative — that goes in handoff.md).
- [PROGRESS.md](PROGRESS.md) — phase-by-phase roadmap and calibration checklist.
- **Rule: every commit updates handoff.md and agentrunbook.md** — overwrite handoff.md's PINNED block to match reality and prepend a new dated session-log entry; append to agentrunbook.md only when you learn something non-obvious. A `.githooks/pre-commit` reminder enforces this softly — enable once per clone with `git config core.hooksPath .githooks`. Trivial commits (typo/formatting) may skip it.

## Current build status
- [x] Dependencies configured
- [x] Project structure scaffolded
- [x] Android permissions & SDK configured
- [x] Theme & Navigation skeleton implemented
- [x] Camera capture screen (countdown, haptic, torch toggle)
- [x] Content-based plate detector (locates strip + wells, white balance, HSV sampling, 3×3 grid)
- [x] Result calculator (Row 1/Row 2 control-calibrated adaptive threshold → Positive/Negative/Invalid + confidence)
- [x] Analysis provider (full pipeline + auto-persist to Hive)
- [x] Result screen (result card, dot grid display, confidence bar)
- [x] History screen (list, delete, clear all, tap to re-view result)
- [x] Hive models (TestResult typeId 0, DotReading typeId 1)
- [ ] Lighting guidance UI (ambient detection, sunlight recommendation)
- [ ] Error states (plate not found, poor image quality)
- [ ] QA on emulator & physical device
