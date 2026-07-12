import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/dot_reading.dart';

enum TestOutcome { positive, negative, invalid }

class AnalysisResult {
  final TestOutcome outcome;
  final double confidence;
  final List<DotReading> readings;

  /// dotIds classed reactive under this analysis's calibrated threshold —
  /// spans all three rows, so the UI can show whether each control behaved
  /// as expected alongside the sample's own classification.
  final Set<String> reactiveDotIds;

  const AnalysisResult({
    required this.outcome,
    required this.confidence,
    required this.readings,
    this.reactiveDotIds = const {},
  });

  String get outcomeString =>
      outcome.name; // 'positive' / 'negative' / 'invalid'
}

/// Judges a plate from its sampled well readings using on-plate calibration:
/// each shot carries its own reference points, so the reactive threshold
/// adapts to that image's lighting/print instead of relying on one fixed
/// global saturation cutoff.
///
///   Row 1 — positive control: reference wells that should always develop.
///           Their average saturation anchors "fully reactive".
///   Row 2 — negative control: reference wells that should always stay clear.
///           Their average saturation anchors "background".
///   Row 3 — sample: the actual patient reagent, judged against the two
///           anchors above rather than a fixed threshold.
class ResultCalculator {
  /// A plate reads positive when at least this many sample wells clear the
  /// adaptive threshold (tolerates one mis-sampled well without flipping the
  /// call).
  static const int _minReactiveInLine = 2;

  /// The sample threshold sits this fraction of the way from the negative-
  /// control anchor to the positive-control anchor. Below 0.5 to catch faint
  /// positives, but far enough from the negative anchor that its own noise
  /// doesn't cross it.
  static const double _thresholdFraction = 0.35;

  /// Minimum saturation gap required between the positive- and negative-
  /// control anchors to trust them. Below this the two controls didn't
  /// differentiate — bad print, bad lighting, or a defective control — so
  /// there's nothing to calibrate a threshold from and the test is invalid.
  static const double _minControlSeparation = 0.08;

  /// When the controls are too close to calibrate a reliable *negative*, two
  /// sample wells may still be sufficiently stronger than both controls to
  /// provide unambiguous positive evidence. This margin prevents a small
  /// sampling fluctuation from bypassing the control-quality check.
  static const double _strongSampleExcess = 0.10;

  AnalysisResult calculate(List<DotReading> readings) {
    if (readings.isEmpty) {
      return const AnalysisResult(
        outcome: TestOutcome.invalid,
        confidence: 0,
        readings: [],
      );
    }

    // Row roles by index: row 1 positive control, row 2 negative control,
    // every row from 3 down is sample. Parsing the row number (rather than a
    // `startsWith('R3')` prefix) keeps this correct if a plate ever carries
    // more than one sample row.
    final posControl = readings.where((d) => _rowOf(d.dotId) == 1).toList();
    final negControl = readings.where((d) => _rowOf(d.dotId) == 2).toList();
    final sample = readings.where((d) => _rowOf(d.dotId) >= 3).toList();

    if (posControl.isEmpty || negControl.isEmpty || sample.isEmpty) {
      // Rows can't be told apart — no control wells to calibrate against.
      return AnalysisResult(
        outcome: TestOutcome.invalid,
        confidence: 0,
        readings: readings,
      );
    }

    final posAnchor = _avgSat(posControl);
    final negAnchor = _avgSat(negControl);

    final controlSeparation = posAnchor - negAnchor;
    final controlsAreReliable = controlSeparation >= _minControlSeparation;
    final threshold = negAnchor + _thresholdFraction * controlSeparation;
    bool clearsThreshold(DotReading d) =>
        d.saturation >= threshold &&
        d.hue >= AppConstants.reactiveHueMin &&
        d.hue <= AppConstants.reactiveHueMax;

    final reactiveDotIds = readings
        .where(clearsThreshold)
        .map((d) => d.dotId)
        .toSet();
    final sampleReactiveCount = sample
        .where((d) => reactiveDotIds.contains(d.dotId))
        .length;
    final strongestControl = math.max(posAnchor, negAnchor);
    final strongSampleCount = sample
        .where(
          (d) =>
              clearsThreshold(d) &&
              d.saturation >= strongestControl + _strongSampleExcess,
        )
        .length;

    // A weak control gap means a negative result would be untrustworthy: the
    // image has not established a dependable background/reactive boundary.
    // It must not, however, erase a plainly stronger two-well sample such as
    // the field capture that prompted this rule. In that case report positive
    // with deliberately capped confidence; otherwise ask for a retake.
    final hasStrongSampleEvidence = strongSampleCount >= _minReactiveInLine;
    if (!controlsAreReliable && !hasStrongSampleEvidence) {
      return AnalysisResult(
        outcome: TestOutcome.invalid,
        confidence: 0,
        readings: readings,
        reactiveDotIds: reactiveDotIds,
      );
    }

    final isPositive = controlsAreReliable
        ? sampleReactiveCount >= _minReactiveInLine
        : hasStrongSampleEvidence;

    // Confidence = how decisively the sample's average sits away from the
    // calibrated threshold, normalized by the control spread.
    final avgSampleSat = _avgSat(sample);
    final margin =
        (avgSampleSat - threshold).abs() /
        (controlSeparation.abs() < 1e-9 ? 1e-9 : controlSeparation.abs());
    final calibratedConfidence = (0.5 + margin).clamp(0.5, 1.0);
    final confidence = controlsAreReliable
        ? calibratedConfidence
        : math.min(
            0.75,
            0.55 +
                ((avgSampleSat - strongestControl) / _strongSampleExcess).clamp(
                      0.0,
                      1.0,
                    ) *
                    0.20,
          );

    return AnalysisResult(
      outcome: isPositive ? TestOutcome.positive : TestOutcome.negative,
      confidence: confidence,
      readings: readings,
      reactiveDotIds: reactiveDotIds,
    );
  }

  double _avgSat(List<DotReading> ds) =>
      ds.map((d) => d.saturation).reduce((a, b) => a + b) / ds.length;

  /// Row index parsed from a `R<row>C<col>` dotId, or -1 if it doesn't match.
  static int _rowOf(String dotId) {
    final m = RegExp(r'^R(\d+)C\d+$').firstMatch(dotId);
    return m == null ? -1 : int.parse(m.group(1)!);
  }
}
