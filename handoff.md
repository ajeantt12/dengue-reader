<!--
HOW TO USE THIS FILE (read this before editing)

This file is cross-tool project memory. It exists because this project is
worked on from multiple apps/models (Claude Code, Codex, others) that don't
share a session history with each other — this file is the substitute for
"the model recalls earlier chats in this project."

Two zones, two different edit rules:

1. PINNED: CURRENT STATE (below) — OVERWRITE every session/commit.
   This is the pickup pointer. It should always describe reality *right now*,
   not history. Stale info here is actively harmful — correct it, don't
   append to it.

2. SESSION LOG (further down) — APPEND ONLY, newest entry at the TOP, with
   a cap. Keep the most recent ~5 entries in full. When adding a 6th, fold
   the oldest full entry into a one- or two-sentence line under "Earlier
   history" at the bottom of the log — don't delete it, don't keep it in
   full forever. `git log` already has the complete diff-level history;
   this journal only needs to keep the *reasoning/narrative* that a diff
   can't carry (why something was tried, what failed and why), and only
   for as long as it's likely to matter. This keeps the file from growing
   into something every future agent has to pay to read in full — see
   agentrunbook.md's "Where to get context from" for the full division of
   labor between this file and git log.

   Always attribute each entry's tool/model honestly. If you find changes
   in the working tree you didn't make (a different session or tool ran
   concurrently), write a separate entry describing what you found rather
   than folding it into your own entry as if you wrote it.

When starting a session: read PINNED, skim the last 2-3 log entries, verify
PINNED against actual repo state (files may have changed since it was
written), then proceed from "Next step."

When ending a session: correct PINNED to match reality, then prepend a new
entry to SESSION LOG (trimming per the cap rule above). Don't skip fields —
write "None" rather than omitting.
-->

# DengueReader — Project Journal

## PINNED: Current State

**Goal:** DengueReader is a Flutter app that photographs dengue rapid-test
cassettes, colour-corrects the shot against a printed reference patch,
samples HSV saturation at 6 fixed dot positions, and reports
Positive/Negative/Invalid. Target users are non-technical lab assistants in
rural India, so capture UX (preview accuracy, lighting guidance, error
recovery) matters as much as the analysis math.

**State right now:** Core pipeline (capture → colour correction → dot
detection → result → history) is implemented and was validated against a
real gold-standard image (`DR005`) per `PROGRESS.md` Phase 2f. Session 1's
camera/UX fixes and the repo-hygiene work from Session 3 are committed.
Session 4 (below) added an in-app version/build label. Phase 2 calibration
(grey-patch RGB, dot-centre coordinates, reference-patch crop position for
the *current* production 3×2/6-dot model) is still print-and-measure
estimates, not verified against a physical plate. Separately, an unfinished,
not-yet-wired-in content-based detector (`PlateDetectorService`, 8×3/24-well
model) exists in the tree — see Session 2 and `agentrunbook.md`'s "Domain
constants" section. Phase 3 (error-state UX) and Phase 4 (device QA) haven't
started. See `PROGRESS.md` for the full phase checklist.

**Files in flight:** A substantial, **uncommitted** set of changes predates
Session 4 and was deliberately left untouched by it (see Session 4's entry —
it only committed the version-label files). As of Session 4's commit, `git
status` still shows uncommitted: `.gitignore`, `CLAUDE.md`,
`analysis_options.yaml`, `app_constants.dart`, `analysis_exception.dart`,
`analysis_screen.dart`, `analysis_provider.dart`, `result_calculator.dart`,
`lighting_indicator.dart`, `camera_provider.dart`, `dot_grid_display.dart`,
`dot_reading.dart` (all modified), plus `colour_correction_service.dart` and
`dot_detector_service.dart` (deleted) and `plate_detector_service.dart` +
`test/plate_detector_test.dart` + `tool/validate_detector.dart` (untracked,
new). This looks like the `PlateDetectorService` migration described in
Session 2/`agentrunbook.md` progressing further (old detector services
deleted, new one being wired in) — **but it wasn't authored or verified by
Session 4, so don't assume it's finished or tested.** Whoever picks this back
up should diff it carefully before committing.

**Open threads** (carried forward until resolved):
- Camera preview fix, torch flicker fix, and torch-off-after-capture fix
  (Session 1) were checked with `flutter analyze` only — still **not**
  verified on a real device/emulator. Needs a physical/emulated camera to
  confirm behavior.
- Phase 2 calibration for the *production* detector (dot centres, reference
  patch position, grey-patch RGB) still needs a real printed colour strip +
  real plate photo — see `PROGRESS.md` 2a–2f.
- `PlateDetectorService` (content-based, 8×3/24-well model) is unfinished
  R&D, now apparently mid-migration into the production pipeline (see "Files
  in flight" above) by a concurrent session/tool not yet identified. Someone
  needs to review that diff, decide whether it's ready, and commit or revert
  it deliberately — don't let it sit uncommitted indefinitely.

**Next step:** Someone needs to review and either commit or revert the
uncommitted `PlateDetectorService`-migration changes described above — run
`dart run tool/validate_detector.dart` first to see current accuracy against
the gold annotated set. Separately, manually verify Session 1's
camera/torch/error-tip fixes on a device or emulator (see the four checks
listed in Session 1's entry below — none of them are confirmed working yet,
only statically analyzed).

---

## Session Log (newest first)

### 2026-07-11 — Session 4 — In-app version/build label — Claude Code / Sonnet 5

**Goal this session:** Add a visible version indicator to the app so a
running build (on a device) can be matched back to the git commit it was
built from — requested directly by the user.

**Changed:**
- Added `package_info_plus` dependency to read the pubspec version/build
  number at runtime.
- Added `tool/gen_build_info.dart` — regenerates
  `lib/core/constants/build_info.dart` (git short commit hash + dirty-tree
  flag + timestamp) from `git rev-parse`/`git status`. Run via `dart run
  tool/gen_build_info.dart`.
- Added `lib/shared/widgets/app_version_label.dart` — combines the pubspec
  version with the commit hash into a label like `v1.0.0+1 · ea24c77` (or
  `-dirty` suffix). Wired into the home screen's app bar title
  (`capture_screen.dart`).
- Extended `.githooks/pre-commit` with a (non-blocking) reminder to
  regenerate `build_info.dart` before a device test.
- Fixed a pre-existing bug in `test/widget_test.dart`: both tests pumped
  `DengueReaderApp` without a `ProviderScope` ancestor, so they always threw
  `StateError: No ProviderScope found` — likely never actually run/checked
  since being written. Wrapped both in `ProviderScope` and added a phone-sized
  test surface (default 800×600 test viewport is shorter than a real phone
  and overflows `CaptureScreen`'s body `Column`).
- Added `.claude/launch.json` (flutter-web preview config) — created to try
  browser-based verification; see "Learned" below for why it wasn't usable.

**Learned:**
- **This project has no web platform support configured** (`flutter run -d
  chrome` fails with "This application is not configured to build on the
  web. To add web support to a project, run `flutter create .`"). UI changes
  in this repo must be verified on Android/Windows/macOS, not via the
  Browser-pane preview flow.
- **Git Bash mangles absolute Unix-style paths passed to `adb`** — e.g. `adb
  shell screencap -p /sdcard/x.png` fails because MSYS path conversion
  rewrites `/sdcard/...` to `C:/Program Files/Git/sdcard/...`. Fix: prefix
  the command with `MSYS_NO_PATHCONV=1`.
- Embedding "the current commit's hash" via a pre-commit hook is inherently
  one commit behind: the hook runs *before* the commit object exists, so
  `git rev-parse HEAD` can only ever see the parent commit. Documented this
  limitation directly in `.githooks/pre-commit` rather than trying to work
  around it (e.g. with a post-commit amend, which would violate the
  no-amend/no-force convention for little benefit).
- `flutter test` surfaces `RenderFlex overflowed` (and other layout
  assertions) as full test failures, not warnings — worth remembering when a
  widget test fails with no obvious assertion mismatch; check for a layout
  overflow first before assuming the widget itself is broken.

**Failed attempts:**
- Tried verifying the label visually via `flutter run -d chrome` through the
  Browser-pane preview tool — abandoned once `preview_logs` showed web
  support isn't configured for this project (see "Learned").
- Tried `adb shell screencap` to grab a screenshot from the connected
  physical Pixel 7a — the device's lock screen required fingerprint auth,
  which is out of bounds to try to bypass. Fell back to a widget test
  instead, which is arguably the better verification anyway (repeatable,
  doesn't depend on device state).

**State at end of session:** `flutter analyze` clean (only the pre-existing
`deprecated_member_use` info in generated router code). `flutter test
test/widget_test.dart` passes (2/2). Verified for real by running `flutter
run -d <Pixel 7a serial>` — app built, installed, and launched with no
exceptions in `adb logcat`. Killed the leftover `flutter`/`dart`/
`flutter_tester` processes afterward. This session's changes were committed
separately from the large pre-existing uncommitted diff already in the
working tree (see PINNED "Files in flight" above) — see `git log` for the
exact commit.

---

### 2026-07-11 — Session 3 — Cross-tool journal cap policy, repo hygiene, commit & push — Claude Code / Sonnet 5

**Goal this session:** Make handoff.md behave as durable cross-tool project
memory (not just a single-session snapshot), commit all outstanding work to
GitHub, and keep APK build artifacts out of git.

**Changed:**
- Restructured `handoff.md` into PINNED (overwritten) + Session Log
  (append-only, newest-first, capped at ~5 full entries — older ones fold
  into a short "Earlier history" line once the cap is hit).
- Added a "Where to get context from" table to `agentrunbook.md` dividing
  labor between `git log` (authoritative diff-level history), `handoff.md`
  PINNED (current state), `handoff.md` Session Log (recent reasoning/narrative
  a diff can't carry), `agentrunbook.md` (durable rules), `PROGRESS.md`
  (roadmap), and `CALIBRATION.md` (detection/calibration research).
- Added `*.apk`, `*.aab`, `*.ipa` to `.gitignore` (existing `/build/` and
  `/apks/` rules already covered the common cases, but not an APK dropped
  anywhere else).
- Updated `CLAUDE.md` and `agentrunbook.md` cross-references to match.

**Learned:**
- **A concurrent session/tool was actively editing this same working
  directory during this session.** `lib/features/analysis/services/plate_detector_service.dart`
  and `tool/validate_detector.dart` changed mtime and content *while this
  session was running* (first `dart analyze` pass caught the detector file
  mid-write — 9 real compile errors referencing methods/variables
  [`_topRow`, `yellowWells`] that didn't exist yet; a re-run 5+ minutes later
  showed 0 errors and a stable file hash across a 5s recheck). Neither file
  was authored in this session — see Session 2 below for what they contain.
  Any agent working in this repo should be aware another tool may be editing
  the same files concurrently and re-check before assuming a snapshot is
  final.
- Confirmed via `dart analyze` (run twice) that this session's own five
  fixes (Session 1) introduce no new errors/warnings beyond one pre-existing
  `deprecated_member_use` info in generated router code.

**Failed attempts:** None.

**State at end of session:** Working tree clean — all of Session 1's fixes,
this session's repo-hygiene files, and the Session-2-discovered detector
R&D were committed together and pushed to `origin/main`. See the commit(s)
on `main` for the exact file list; `git log` is the source of truth for what
landed.

---

### 2026-07-11 — Session 2 — Content-based plate detector (WIP, unfinished) — unknown tool/session, discovered not authored here

**Goal (inferred from code/CALIBRATION.md, not confirmed with whoever wrote
it):** Replace the fixed-position 3×2/6-dot detection model with a
content-based one that locates the plate from its printed CMYK colour strip
and works regardless of framing/rotation, per the design already documented
in the (pre-existing, already-committed) `assets/research/CALIBRATION.md`.

**Changed** (found already in the working tree, not made by Session 1 or
Session 3):
- Added `lib/features/analysis/services/plate_detector_service.dart` (643
  lines) — segments the image into HSV hue bands to find blobs, locates the
  strip's magenta/cyan/yellow/orange patches, fits an affine canonical→image
  transform from those landmarks, and projects an 8×3/24-well grid plus the
  strip's neutral patches for white-balancing.
- Added `tool/validate_detector.dart` — a harness that runs
  `PlateDetectorService` against the 4 annotated gold images in
  `assets/research/samples/annotations/` and prints detected vs.
  ground-truth well centres/saturations.
- Added `tool/_dbg.dart` — a throwaway single-file script for eyeballing
  HSV blob segmentation on `DR009.jpeg` directly (minified, print-based,
  not meant as production code).

**Learned:** `PlateDetectorService` is **not imported anywhere in `lib/`** —
it isn't wired into `analysis_provider.dart` or any screen. This is
intentional per `CALIBRATION.md`'s own migration note: rewriting
`app_constants.dart` and the production pipeline to the new 8×3 grid is
called out as "a separate, deliberate step," deferred on purpose so it
doesn't break the currently-working 3×2 pipeline mid-edit.

**Failed attempts:** Unknown — not visible from the code alone. Whoever
resumes this should run `dart run tool/validate_detector.dart` first to see
current accuracy against the gold set before changing anything.

**State at end of session (as observed, not as ended by anyone):** File
compiles cleanly as of the last check in Session 3's entry above, but was
caught mid-edit at least once during this conversation — treat it as
actively in-progress, not finished or stable, and check with whoever owns
that session before assuming its current shape is final.

---

### 2026-07-11 — Session 1 — Camera capture UX fixes — Claude Code / Sonnet 5

**Goal this session:** Fix bugs found in the capture flow: distorted camera
preview, torch flicker, torch staying on after capture, and unhelpfully
terse error messages.

**Changed:**
1. **Camera preview distortion fix** — `_CoverCameraPreview` in
   `capture_screen.dart` previously used `Transform.scale` sized off
   `controller.value.aspectRatio` fed into `AspectRatio`. On devices like the
   Pixel 7a this produced a short, wide, letterboxed preview. Root cause:
   `CameraController.value.previewSize` is always reported in the sensor's
   native **landscape** orientation (width > height) regardless of device
   orientation. Fix: read `previewSize`, swap width/height, let
   `FittedBox(fit: BoxFit.cover)` inside `OverflowBox` do the scaling instead
   of a manual `Transform.scale` factor.
2. **Torch flicker fix** — `_autoTorch` had a hysteresis band
   (`torchOnThreshold` 0.18 / `torchOffThreshold` 0.40) plus a switch
   cooldown, but still flickered. Root cause: the torch's own light
   overwhelms the brightness sample the heuristic reads, so *any* auto-off
   rule driven by that same signal creates a feedback loop (torch on → frame
   reads bright → torch off → frame reads dark → torch on → …). Fix: removed
   `torchOffThreshold` and all auto-off logic. Auto-torch now only ever turns
   the torch **on**; turning off requires a manual `TorchMode` cycle.
3. **Torch left on after capture** — `captureImage()` stopped the stream and
   took the picture but never touched the torch. `CameraControllerNotifier`
   isn't disposed when navigating to the analysis screen (camera route stays
   underneath in the go_router stack), so the torch stayed lit — pointed at
   nothing — for as long as the user was on the analysis/result screen. Fix:
   `captureImage()` now calls `_setTorch(false)` after `takePicture()`,
   without touching `_torchMode`.
4. **Structured error tips** — error strings previously embedded advice via
   hardcoded `\n` inside `userMessage` (e.g. `'Image is too
   dark.\nMove to a brighter area or enable flash.'`). Refactored into a
   `tips: List<String>` field on `DengueAnalysisException`, rendered by
   `analysis_screen.dart` as a bulleted card.
5. **Bright-light tip surfaced earlier** — `LightingIndicator` (shown live
   during framing) now shows `'Avoid direct sunlight · Try without flash'`
   when brightness crosses into `LightLevel.bright`, pre-empting the
   post-capture `ImageOverexposedException` message.

**Learned** (promoted to [agentrunbook.md](agentrunbook.md) — see there for
the durable version):
- `previewSize` is landscape-native regardless of device orientation.
- Auto-torch must be on-only; auto-off on brightness is a guaranteed feedback
  loop.
- `CameraControllerNotifier` outlives navigation to the analysis screen.

**Failed attempts:** None tried-and-abandoned this session. Note: the
*previous* commit (`ea24c77 Fix camera flash flicker and stretched preview;
add flash toggle`) was an earlier, incomplete attempt at fixes #1 and #2
above — see the removed hysteresis-band comment in `app_constants.dart`'s
git history for what that first attempt looked like, in case the new
approach also turns out incomplete.

**State at end of session:** All 5 fixes made, none committed, none verified
on-device. `git diff --stat`: 6 files changed, 137 insertions, 54 deletions.

**Also this session:** Set up cross-tool project memory — created this
journal structure for `handoff.md`, created
[agentrunbook.md](agentrunbook.md) (durable technical rules/footguns, as
opposed to this file's session narrative), added a `.githooks/pre-commit`
reminder (non-blocking) for commits that don't touch either file, and
pointed to both from [CLAUDE.md](CLAUDE.md).
