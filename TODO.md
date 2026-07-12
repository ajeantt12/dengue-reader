# to-do list

1. ~~Change the diagram on the test results to denote the new approach.~~ Done —
   `ResultCalculator` now derives the reactive threshold from Row 1 (positive
   control) and Row 2 (negative control), and judges Row 3 (the sample) against
   it. `DotGridDisplay` labels the rows accordingly and colours wells from that
   calibrated threshold instead of a fixed cutoff.
2. ~~Add image upload option along with click as well.~~ Done (was already
   implemented) — the home screen has an "Upload from Gallery" card
   (`_pickFromGallery`, `image_picker`) alongside "Take a Photo", both feeding
   the same analysis route.
3. ~~Various orientations of the colour reference plate and wells.~~ Decided +
   done. Decision (with user, 2026-07-12): keep a **single fixed overlay/
   orientation** (users align to the on-screen guide; no auto-rotation), the
   colour strip is identical across all plates, and the real variability is
   **wells per row (columns)**. Implemented as a user-picked `wellsPerRow`
   setting (home-screen stepper, 2–6, default 3) threaded into
   `PlateDetectorService.analyse(gridCols:)`; rows stay fixed at three (pos
   control / neg control / sample) and `ResultCalculator` now treats any row
   ≥ 3 as sample. NOTE: only static-verified for column counts other than 3 —
   the gold set is all 3-column, so a real non-3-column plate photo should be
   shot to validate detection geometry end-to-end.
4. ~~Export data should download image files as well; store all shot images in
   app data.~~ Done — captures are copied into `<app documents>/captures/<id>`
   at analysis time (camera temp files / gallery originals can vanish), and
   `CsvExportService` now bundles the CSV + every stored image into a single
   `.zip` share. Deleting/clearing history also removes the owned capture files
   (never a user's original gallery photo).
5. ~~Data loss across an .apk update sent to the research team.~~ Answered +
   surfaced in-app. `applicationId` is fixed (`com.denguereader.dengue_reader`),
   so an install-over update (a new APK over the old app, or a Play update)
   **keeps all Hive data + images**. Data is only lost on a full uninstall or
   storage-clear. So the team does **not** need to export before every update —
   only before an uninstall. There's now an ℹ️ note on the History screen
   explaining this.
6. ~~Toggle the pre-capture timer on/off.~~ Done — a persisted `useCountdown`
   setting (timer icon on the camera screen) skips the 3-2-1 countdown and
   captures immediately when off.
