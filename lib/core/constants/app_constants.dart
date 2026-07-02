class AppConstants {
  // Hysteresis band for auto-torch: torch turns ON below the low threshold
  // and OFF above the high threshold. The gap prevents the flash from
  // glaring the scene bright enough to immediately switch itself off again
  // (which previously caused a rapid on/off flicker loop).
  static const double torchOnThreshold = 0.18;
  static const double torchOffThreshold = 0.40;

  // Minimum time between automatic torch switches, as a second safeguard
  // against flicker from transient brightness spikes (e.g. glare).
  static const Duration torchSwitchCooldown = Duration(milliseconds: 1200);
  static const int countdownSeconds = 3;

  // Reference patch — top-right corner (normalized, relative to full image)
  static const double referencePatchX = 0.80;
  static const double referencePatchY = 0.05;
  static const double referencePatchSize = 0.08;
  static const List<int> referenceKnownRgb = [200, 200, 200];

  static const double saturationThreshold = 0.35;

  // 3-row × 2-col dot grid (normalized x,y centre positions, radius in px)
  // Plate occupies centre 60% of the captured image horizontally and ~70% vertically.
  // Origin (0,0) is top-left of the full image.
  // Row 1 = top row (control), Row 2 = IgM, Row 3 = IgG
  static const double dotRadius = 18.0;

  static const Map<String, List<double>> dotCentres = {
    'R1C1': [0.37, 0.30],
    'R1C2': [0.63, 0.30],
    'R2C1': [0.37, 0.50],
    'R2C2': [0.63, 0.50],
    'R3C1': [0.37, 0.70],
    'R3C2': [0.63, 0.70],
  };
}
