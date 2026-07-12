/// User-adjustable capture/analysis preferences.
///
/// These are plain values persisted in an untyped Hive box (no `@HiveType`
/// adapter/typeId), so adding a field here needs no code generation and can
/// never collide with the `TestResult`/`DotReading` typeIds.
class AppSettings {
  /// Wells per row (columns) on the plate being read. Rows are fixed at three
  /// (positive control, negative control, sample); only the column count
  /// varies between plate designs, and the user picks it before capture.
  static const int minWellsPerRow = 2;
  static const int maxWellsPerRow = 6;
  static const int defaultWellsPerRow = 3;

  final int wellsPerRow;

  /// Whether the camera runs the 3-2-1 countdown before capturing. When false,
  /// tapping the shutter captures immediately.
  final bool useCountdown;

  const AppSettings({
    required this.wellsPerRow,
    required this.useCountdown,
  });

  AppSettings copyWith({int? wellsPerRow, bool? useCountdown}) => AppSettings(
        wellsPerRow: wellsPerRow ?? this.wellsPerRow,
        useCountdown: useCountdown ?? this.useCountdown,
      );
}
