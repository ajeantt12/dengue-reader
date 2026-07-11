import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';

part 'dot_reading.g.dart';

@HiveType(typeId: 1)
class DotReading extends HiveObject {
  @HiveField(0)
  final String dotId; // e.g. 'R1C1'

  @HiveField(1)
  final double hue;

  @HiveField(2)
  final double saturation;

  @HiveField(3)
  final double value;

  @HiveField(4)
  final int rawR;

  @HiveField(5)
  final int rawG;

  @HiveField(6)
  final int rawB;

  DotReading({
    required this.dotId,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.rawR,
    required this.rawG,
    required this.rawB,
  });

  /// A reactive well is a developed (yellow) reagent dot: hue in the yellow
  /// band and saturation above threshold. Clear/negative wells fail the hue
  /// gate even when their residual saturation is comparable.
  bool get isReactive =>
      hue >= AppConstants.reactiveHueMin &&
      hue <= AppConstants.reactiveHueMax &&
      saturation >= AppConstants.saturationThreshold;
}
