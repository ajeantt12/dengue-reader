import 'package:flutter_test/flutter_test.dart';

import 'package:dengue_reader/features/analysis/services/result_calculator.dart';
import 'package:dengue_reader/shared/models/dot_reading.dart';

DotReading _reading(String id, double saturation, {double hue = 60}) =>
    DotReading(
      dotId: id,
      hue: hue,
      saturation: saturation,
      value: 0.8,
      rawR: 0,
      rawG: 0,
      rawB: 0,
    );

void main() {
  group('ResultCalculator', () {
    test('reports a clearly stronger two-well sample as positive', () {
      // Reproduces the 11 July field capture: the positive/negative controls
      // are close together after sampling, but R3C1/R3C2 are unambiguously
      // more saturated yellow wells.
      final readings = [
        _reading('R1C1', 0.15),
        _reading('R1C2', 0.07),
        _reading('R1C3', 0.10),
        _reading('R2C1', 0.09, hue: 0),
        _reading('R2C2', 0.06, hue: 0),
        _reading('R2C3', 0.10, hue: 0),
        _reading('R3C1', 0.43),
        _reading('R3C2', 0.50),
        _reading('R3C3', 0.09, hue: 0),
      ];

      final result = ResultCalculator().calculate(readings);

      expect(result.outcome, TestOutcome.positive);
      expect(result.reactiveDotIds, containsAll({'R3C1', 'R3C2'}));
    });

    test('does not call a weak-control, non-reactive sample negative', () {
      final readings = [
        _reading('R1C1', 0.15),
        _reading('R1C2', 0.07),
        _reading('R1C3', 0.10),
        _reading('R2C1', 0.09, hue: 0),
        _reading('R2C2', 0.06, hue: 0),
        _reading('R2C3', 0.10, hue: 0),
        _reading('R3C1', 0.10, hue: 0),
        _reading('R3C2', 0.08, hue: 0),
        _reading('R3C3', 0.09, hue: 0),
      ];

      final result = ResultCalculator().calculate(readings);

      expect(result.outcome, TestOutcome.invalid);
    });
  });
}
