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

  // Visible well grid on a close-up capture: 3 rows × 3 columns. The top row is
  // the reactive (test) line — a positive plate develops it yellow. See
  // assets/research/CALIBRATION.md. Well positions are no longer hard-coded:
  // PlateDetectorService locates the wells by scanning the whole bright frame.
  static const int gridRows = 3;
  static const int gridCols = 3;
}
