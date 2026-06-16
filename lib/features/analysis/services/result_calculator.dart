import '../../../core/constants/app_constants.dart';
import '../../../shared/models/dot_reading.dart';

enum TestOutcome { positive, negative, invalid }

class AnalysisResult {
  final TestOutcome outcome;
  final double confidence;
  final List<DotReading> readings;

  const AnalysisResult({
    required this.outcome,
    required this.confidence,
    required this.readings,
  });

  String get outcomeString => outcome.name; // 'positive' / 'negative' / 'invalid'
}

class ResultCalculator {
  AnalysisResult calculate(List<DotReading> readings) {
    if (readings.isEmpty) {
      return AnalysisResult(outcome: TestOutcome.invalid, confidence: 0, readings: readings);
    }

    // Control dot (R1C1) must be reactive for a valid test
    final control = readings.where((d) => d.dotId == 'R1C1').firstOrNull;
    if (control == null || !control.isReactive) {
      return AnalysisResult(outcome: TestOutcome.invalid, confidence: 0, readings: readings);
    }

    // IgM row (R2C1, R2C2) — any reactive dot = positive
    final igmDots = readings.where((d) => d.dotId == 'R2C1' || d.dotId == 'R2C2');
    final igmPositive = igmDots.any((d) => d.isReactive);

    // IgG row (R3C1, R3C2)
    final iggDots = readings.where((d) => d.dotId == 'R3C1' || d.dotId == 'R3C2');
    final iggPositive = iggDots.any((d) => d.isReactive);

    final isPositive = igmPositive || iggPositive;

    // Confidence: how far the reactive dots are above/below threshold
    final reactiveDots = isPositive
        ? readings.where((d) => d.dotId != 'R1C1' && d.isReactive)
        : readings.where((d) => d.dotId != 'R1C1' && !d.isReactive);

    double confidence = 0.5;
    if (reactiveDots.isNotEmpty) {
      final avgDistance = reactiveDots
          .map((d) => (d.saturation - AppConstants.saturationThreshold).abs())
          .reduce((a, b) => a + b) / reactiveDots.length;
      confidence = (0.5 + avgDistance * 2).clamp(0.5, 1.0);
    }

    return AnalysisResult(
      outcome: isPositive ? TestOutcome.positive : TestOutcome.negative,
      confidence: confidence,
      readings: readings,
    );
  }
}
