import 'package:uuid/uuid.dart';
import '../../../shared/models/dot_reading.dart';
import '../../../shared/models/test_result.dart';

enum DemoScenario { positive, negative, invalid }

class DemoService {
  TestResult buildDemo(DemoScenario scenario) {
    return TestResult(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      outcome: _outcome(scenario),
      confidence: _confidence(scenario),
      dotReadings: _readings(scenario),
      imagePath: '',
    );
  }

  String _outcome(DemoScenario s) => switch (s) {
        DemoScenario.positive => 'positive',
        DemoScenario.negative => 'negative',
        DemoScenario.invalid => 'invalid',
      };

  double _confidence(DemoScenario s) => switch (s) {
        DemoScenario.positive => 0.88,
        DemoScenario.negative => 0.82,
        DemoScenario.invalid => 0.0,
      };

  List<DotReading> _readings(DemoScenario scenario) {
    // Based on observed real plate: reactive = yellow (hue ~60°, sat ~0.65, val ~0.85)
    //                                non-reactive = clear (sat ~0.05, val ~0.90)
    return switch (scenario) {
      DemoScenario.positive => [
          _dot('R1C1', sat: 0.64, hue: 61, val: 0.86, r: 219, g: 210, b: 77),  // control ✓
          _dot('R1C2', sat: 0.62, hue: 59, val: 0.85, r: 216, g: 207, b: 80),  // control ✓
          _dot('R2C1', sat: 0.66, hue: 63, val: 0.84, r: 214, g: 209, b: 73),  // IgM ✓
          _dot('R2C2', sat: 0.61, hue: 58, val: 0.83, r: 212, g: 205, b: 82),  // IgM ✓
          _dot('R3C1', sat: 0.05, hue: 0,  val: 0.91, r: 232, g: 230, b: 228), // IgG –
          _dot('R3C2', sat: 0.04, hue: 0,  val: 0.90, r: 229, g: 228, b: 226), // IgG –
        ],
      DemoScenario.negative => [
          _dot('R1C1', sat: 0.63, hue: 60, val: 0.87, r: 221, g: 212, b: 81),  // control ✓
          _dot('R1C2', sat: 0.61, hue: 58, val: 0.86, r: 218, g: 209, b: 84),  // control ✓
          _dot('R2C1', sat: 0.05, hue: 0,  val: 0.90, r: 230, g: 228, b: 225), // IgM –
          _dot('R2C2', sat: 0.04, hue: 0,  val: 0.91, r: 232, g: 230, b: 228), // IgM –
          _dot('R3C1', sat: 0.04, hue: 0,  val: 0.89, r: 228, g: 226, b: 224), // IgG –
          _dot('R3C2', sat: 0.05, hue: 0,  val: 0.90, r: 230, g: 229, b: 227), // IgG –
        ],
      DemoScenario.invalid => [
          _dot('R1C1', sat: 0.04, hue: 0,  val: 0.88, r: 225, g: 223, b: 221), // control FAIL
          _dot('R1C2', sat: 0.05, hue: 0,  val: 0.89, r: 227, g: 225, b: 223),
          _dot('R2C1', sat: 0.06, hue: 0,  val: 0.87, r: 222, g: 220, b: 218),
          _dot('R2C2', sat: 0.04, hue: 0,  val: 0.88, r: 224, g: 222, b: 220),
          _dot('R3C1', sat: 0.05, hue: 0,  val: 0.90, r: 230, g: 228, b: 226),
          _dot('R3C2', sat: 0.04, hue: 0,  val: 0.89, r: 228, g: 226, b: 224),
        ],
    };
  }

  DotReading _dot(String id,
          {required double sat,
          required double hue,
          required double val,
          required int r,
          required int g,
          required int b}) =>
      DotReading(
          dotId: id, hue: hue, saturation: sat, value: val, rawR: r, rawG: g, rawB: b);
}
