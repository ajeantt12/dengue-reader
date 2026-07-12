class AppConstants {
  // Auto-torch turns ON below this ambient brightness. There is no auto-OFF
  // threshold: the torch's own light overwhelms the brightness reading, so
  // auto-switching off based on that same signal caused an endless on/off
  // strobe. Once auto-torch turns it on, only a manual toggle turns it off.
  static const double torchOnThreshold = 0.18;

  // Minimum time before auto-torch is allowed to fire, as a guard against
  // reacting to transient brightness dips right after the stream starts.
  static const Duration torchSwitchCooldown = Duration(milliseconds: 1200);
  static const int countdownSeconds = 3;

  // Reference patch — top-right corner (normalized, relative to full image)
  static const double referencePatchX = 0.80;
  static const double referencePatchY = 0.05;
  static const double referencePatchSize = 0.08;
  static const List<int> referenceKnownRgb = [200, 200, 200];

  // A well is reactive (a developed reagent dot) when its colour-corrected
  // hue sits in the yellow band AND its saturation clears the threshold.
  // The hue gate matters: clear/negative wells pick up a faint blue-grey cast
  // after white balance, so hue alone separates them from faint yellows.
  static const double saturationThreshold = 0.25;
  static const double reactiveHueMin = 40;
  static const double reactiveHueMax = 80;

  // Well grid on a close-up capture: 3 rows (row 1 positive control, row 2
  // negative control, row 3 sample — see ResultCalculator). The column count
  // (wells per row) varies between plate designs and is chosen by the user
  // before capture, so it lives in AppSettings, not here; PlateDetectorService
  // takes it as a `gridCols` argument (default PlateDetectorService.defaultGridCols).
  // Well positions themselves are never hard-coded: the detector locates the
  // wells by scanning the whole bright frame. See assets/research/CALIBRATION.md.
  static const int gridRows = 3;
}
