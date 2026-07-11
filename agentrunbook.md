# Agent Runbook — DengueReader

Practical rules for any AI agent (Claude Code or otherwise) working in this
repo. This is technical/procedural guidance — for what the app *does*, read
[CLAUDE.md](CLAUDE.md); for where the current session left off, read
[handoff.md](handoff.md); for the phase-by-phase roadmap and calibration
checklist, read [PROGRESS.md](PROGRESS.md).

## Where to get context from

This project is worked on from multiple apps/models with no shared session
history, so context is spread across a few sources on purpose — don't read
just one and assume it's complete:

| Source | What it's for | What it's NOT for |
|---|---|---|
| `git log` / `git show` | The authoritative, can't-drift record of *what* changed and *when*, at diff granularity. Always accurate — it's generated from real commits, not hand-maintained. Use it when you need to know exactly what a past change touched. | Narrative reasoning, dead ends, cross-session continuity — commit messages are per-change, not a running story. |
| [handoff.md](handoff.md) PINNED block | The current state, right now — goal, what's in flight, open threads, next step. Read this first, every session. | History — it's overwritten each session, so it has no memory of its own. |
| [handoff.md](handoff.md) Session Log | The *why* behind recent work — reasoning, failed attempts, what was learned — that a diff alone can't carry. Capped at ~5 full entries; older ones are folded into a one-line summary, so don't expect it to go back to project start. | Full project history (that's what git log is for) or a substitute for reading the actual diff. |
| [agentrunbook.md](agentrunbook.md) (this file) | Durable rules and footguns that stay true regardless of which session discovered them — framework quirks, load-bearing invariants, conventions. | Anything time-bound or session-specific — that belongs in a handoff.md entry, not here. |
| [PROGRESS.md](PROGRESS.md) | The phase-by-phase roadmap and calibration checklist — what's done, what's left, in what order. | Session-level detail on *how* something was done. |
| [CALIBRATION.md](assets/research/CALIBRATION.md) | Plate-geometry and colour-calibration research/design decisions specifically (see "Domain constants" below — this is where the *new* detection model is documented). | General app architecture — it's scoped to the detection/calibration research track. |

If a memory in one source contradicts another (e.g. CLAUDE.md still describes
an older domain model than what the code does), trust the code and the most
recent handoff.md entry, then fix the stale doc rather than propagating the
contradiction.

## Commit discipline

- **[handoff.md](handoff.md) is cross-tool project memory** — this project is
  worked on from multiple apps/models (Claude Code, Codex, others) that don't
  share session history, so this file substitutes for "the model recalls
  earlier chats in this project." It has two zones with different edit
  rules, documented at the top of the file itself:
  - **PINNED: Current State** — overwrite every session/commit to match
    reality right now. Stale info here is actively harmful.
  - **Session Log** — append-only, newest entry at the top, capped at ~5
    full entries (older ones get folded into a short "Earlier history"
    summary rather than kept verbatim forever — git log already has the
    full diff record, so the journal doesn't need to). Never edit or delete
    a past entry other than that scheduled fold. Every session/commit adds
    one dated entry (goal, changed, learned, failed attempts, state at end),
    honestly attributed to whichever tool/model made the change — if you
    find changes you didn't make, log them as a separate, distinctly
    attributed entry rather than folding them into your own.
- **Update [agentrunbook.md](agentrunbook.md)** (this file) whenever you learn
  something a future agent would otherwise have to rediscover the hard way —
  a non-obvious framework quirk, a footgun, a convention that isn't written
  down elsewhere. This file only holds durable rules, not session narrative —
  session-specific detail belongs in a handoff.md journal entry instead.
- A local git hook (`.githooks/pre-commit`) prints a reminder if a commit
  doesn't touch either file. It's a nudge, not a block — use judgment for
  trivial commits (typo fixes, formatting) where updating both would be
  noise. Enable it once per clone: `git config core.hooksPath .githooks`.

## Code generation — do not hand-edit generated files

This project uses `@riverpod` (riverpod_generator) and `@HiveType` (hive_generator)
with `build_runner`. Files ending in `.g.dart` (e.g. `camera_provider.g.dart`,
`test_result.g.dart`) are generated — **never edit them by hand**. After
changing any `@riverpod`-annotated class or any `@HiveType`/`@HiveField` model,
regenerate:

```
flutter pub run build_runner build --delete-conflicting-outputs
```

If a provider or Hive adapter reference doesn't resolve, this is almost
always the fix — check whether the `.g.dart` file is stale before assuming
the code itself is wrong.

## Hive typeIds are load-bearing

`TestResult` is `typeId: 0`, `DotReading` is `typeId: 1`
([lib/shared/models/test_result.dart:6](lib/shared/models/test_result.dart), [lib/shared/models/dot_reading.dart:5](lib/shared/models/dot_reading.dart)).
Both adapters are registered in [lib/main.dart](lib/main.dart) before
`runApp`. If you add a new `@HiveType` model, give it the next unused
integer and never reuse or renumber an existing typeId — Hive uses it to
decode already-persisted boxes on-device, so changing an existing model's
typeId corrupts every user's saved history on their next app launch.

## Camera quirks (learned the hard way this session — see handoff.md)

- `CameraController.value.previewSize` is reported in the sensor's native
  **landscape** orientation (width > height) regardless of device/preview
  orientation. Any code that sizes the preview must swap width/height first,
  or portrait devices get a stretched/letterboxed preview. See
  `_CoverCameraPreview` in
  [lib/features/capture/presentation/capture_screen.dart](lib/features/capture/presentation/capture_screen.dart).
- Auto-torch must be **on-only**. Torch light overwhelms the ambient
  brightness reading the heuristic uses, so any auto-off rule driven by that
  same signal creates an on/off feedback loop (strobing flash). Once
  auto-torch fires, only an explicit user action may turn it off — see
  `_autoTorch` in
  [lib/features/capture/providers/camera_provider.dart](lib/features/capture/providers/camera_provider.dart).
- `CameraControllerNotifier` is **not disposed** when navigating from the
  camera screen to the analysis screen — the camera route stays underneath
  in the go_router stack. Anything that should stop when the user leaves the
  viewfinder (e.g. the torch) must be explicitly turned off in
  `captureImage()`, not left to `ref.onDispose`.

## Domain constants — don't touch without calibration data

Everything in [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart)
(`dotCentres`, `referencePatchX/Y/Size`, `referenceKnownRgb`,
`saturationThreshold`) is a physical-world calibration value, not a UI
tuning knob. Changing any of these without a real plate photo and measured
values (per `PROGRESS.md` Phase 2) will silently break result accuracy —
there's no automated test that would catch a bad dot-centre coordinate. If
asked to "fix" a detection bug, check whether it's a code bug or a
calibration-data problem before changing constants.

**The content-based detector migration is now wired in — CLAUDE.md is stale
on this point, trust this file and the code.**
[lib/features/analysis/services/plate_detector_service.dart](lib/features/analysis/services/plate_detector_service.dart)
(locates the plate via its printed CMYK colour strip, projects a 3×3-well
grid via an affine/reactive-row layout) replaced the old fixed-position
`dot_detector_service.dart`/`colour_correction_service.dart` (deleted) and is
what `analysis_provider.dart` actually calls. `CLAUDE.md`'s "3-row × 2-col"
grid description is out of date — the live grid is 3×3, per
`AppConstants.gridRows/gridCols`.

**Row roles changed again on top of that (this session) — old gold-photo
tests do NOT validate current outcome semantics.**
[lib/features/analysis/services/result_calculator.dart](lib/features/analysis/services/result_calculator.dart)
no longer treats row 1 as "the" reactive test line. It now reads the grid as
an on-plate calibration: **row 1 = positive control** (anchors "fully
reactive"), **row 2 = negative control** (anchors "background"), **row 3 =
sample** (judged against those two anchors via `_thresholdFraction`, not the
fixed `AppConstants.saturationThreshold`). `DotReading.isReactive` (the old
fixed-threshold getter) still exists and is still exercised by some tests,
but it is **no longer what production classification uses** — that's
`ResultCalculator.calculate(...).reactiveDotIds`, computed fresh from
whatever anchors that specific image's controls produce.

Gotcha: the gold research photos (`DR005`/`DR008`/`DR009`/`DR010` in
`assets/research/samples/`) were shot and annotated under the *old*
single-test-line design — their row 3 never developed, because in that
design row 3 was just a filler negative, not a sample well. Under the new
control-row scheme they correctly classify as NEGATIVE even though their
annotation says `ground-truth: POSITIVE` (see `tool/validate_detector.dart`
output) — that mismatch is expected, not a regression, until the gold set is
reshot on the new control-row plate design. `test/plate_detector_test.dart`
was updated to only assert what's still physically true of those photos
(the positive-control row itself reads reactive), not the overall outcome.
Don't "fix" that mismatch by loosening the threshold — reshoot the gold set
on the new plate design instead.

**Weak control separation is asymmetric.** A small Row 1/Row 2 saturation
gap cannot safely support a negative result, so it normally produces
`Invalid`. Do not let that gate erase repeated, strong yellow sample evidence:
if at least two Row 3 wells are each at least 0.10 saturation above both
control averages, `ResultCalculator` reports `Positive` (at capped
confidence). This is deliberately stricter than merely being higher than a
control, which could be sampling noise; the values are regression-covered in
`test/result_calculator_test.dart` from the 2026-07-11 field capture.

## Testing / verification

There is no camera-hardware test harness — `captureImage`, `_autoTorch`, and
the preview widget can only be verified on a real device or emulator with a
working camera. `flutter analyze` and `flutter test` catch compile errors
and pure-Dart logic (colour correction, dot detection, result calculation)
but not capture-flow UX regressions. When touching anything under
`lib/features/capture/`, say explicitly in your summary whether you verified
on-device or only statically — don't imply device-tested behavior you didn't
observe.

- **No web platform support is configured for this project.** `flutter run -d
  chrome` fails outright ("This application is not configured to build on
  the web"). Verify UI changes on Android/Windows/macOS, not via a browser
  preview flow.
- **`flutter install` does not reliably rebuild before installing.** It can
  silently reinstall a stale APK already sitting in
  `build/app/outputs/flutter-apk/` instead of recompiling your latest source
  changes — with no warning, and a suspiciously fast "Installing..." step
  (~7s) instead of a real release build (~4-5 min) is the tell. Confirmed
  this session: two consecutive `flutter install` calls after real source
  edits both silently reused a 70+ minute-old APK, so the device kept
  running old UI/logic while every visible signal (command output, exit
  code) looked like a normal successful install. Before trusting an on-device
  check, run `flutter clean && flutter build apk --release` explicitly, then
  `adb install -r build/app/outputs/flutter-apk/app-release.apk` (or `flutter
  install`) — and sanity-check the APK's mtime against your last edit's mtime
  if anything looks off.
- **Widget tests must wrap the app in `ProviderScope`.** `DengueReaderApp` is
  a `ConsumerWidget` — pumping it bare throws `StateError: No ProviderScope
  found`. `test/widget_test.dart` had this bug for both of its tests until
  Session 4 fixed it; check whether a "failing" widget test is actually
  broken app code before debugging further.
- **The default test surface (800×600) is shorter than a real phone** and
  will trip a `RenderFlex overflowed` failure in `CaptureScreen`'s body. Set
  `tester.view.physicalSize`/`devicePixelRatio` to phone-like dimensions
  (e.g. 1080×2400 / 1.0) before pumping screens with real content, or the
  test fails on layout, not on your actual assertion.
- **In Git Bash, `adb` mangles absolute Unix-style paths** — `adb shell
  screencap -p /sdcard/x.png` gets rewritten to `C:/Program
  Files/Git/sdcard/x.png` by MSYS path conversion. Prefix such commands with
  `MSYS_NO_PATHCONV=1`.

## In-app version label (build_info.dart)

**Current convention (2026-07-11):**
[lib/core/constants/build_info.dart](lib/core/constants/build_info.dart)
reads the `GIT_COMMIT` compile-time value; it is normal tracked source, not a
generated file. [AppVersionLabel](lib/shared/widgets/app_version_label.dart)
also reads the installed app version/build number via `package_info_plus`, so
the header shows `v<version>+<build> · Build <commit>`. Build a
device/release APK with the exact commit after it exists, for example `flutter build apk --release
--dart-define=GIT_COMMIT=<short-hash>`. Without that argument, local/debug
builds deliberately display `Build development` rather than a misleading
commit hash. Do not reintroduce a source file stamped before commit time:
Git cannot know a commit's hash until the commit has been created.

## Conventions (see also CLAUDE.md)

- No `StatefulWidget` except where a screen genuinely needs local transient
  UI state Riverpod shouldn't own (e.g. `CameraViewfinderScreen`'s countdown
  timer). Default to `ConsumerWidget`.
- All colours through `app_colors.dart`; all magic numbers describing plate
  geometry through `app_constants.dart`. Don't inline either.
- Exceptions that reach the UI extend `DengueAnalysisException` and separate
  the headline (`userMessage`) from actionable next steps (`tips`) — don't
  concatenate advice into `userMessage` with `\n`.
