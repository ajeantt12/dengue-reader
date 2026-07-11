// Validation harness for PlateDetectorService against the gold research set.
//
//   dart run tool/validate_detector.dart
//
// For each annotated gold image it prints the detected well centres and
// sampled saturations next to the hand-annotated ground truth, so we can see
// whether the content-based detector lands on the wells.

import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

import '../lib/features/analysis/services/plate_detector_service.dart';
import '../lib/features/analysis/services/result_calculator.dart';
import '../lib/core/exceptions/analysis_exception.dart';

const samplesDir = 'assets/research/samples';
const annoDir = 'assets/research/samples/annotations';
const goldIds = ['DR005', 'DR008', 'DR009', 'DR010'];

void main() {
  var totalErr = 0.0;
  var totalPts = 0;
  for (final id in goldIds) {
    print('\n=== $id ===');
    final annoFile = File('$annoDir/$id.json');
    final anno = jsonDecode(annoFile.readAsStringSync()) as Map<String, dynamic>;
    final bytes = File('$samplesDir/$id.jpeg').readAsBytesSync();
    final image = img.decodeImage(bytes)!;

    // Ground-truth well centres (original px) via the annotation's bilinear grid.
    final pc = anno['plate_corners_px'] as Map<String, dynamic>;
    final gtCentres = _gridCentres(pc, 3, 3); // list of [x,y] in original px

    PlateDetectionResult res;
    try {
      res = PlateDetectorService().analyse(image, assertQuality: false);
    } on DengueAnalysisException catch (e) {
      print('  DETECTION FAILED: ${e.runtimeType} — ${e.userMessage}');
      continue;
    }

    final s = res.workScale;
    final outcome = ResultCalculator().calculate(res.readings);
    final gtPositive =
        (anno['labels']['positive_cells'] as List).isNotEmpty;
    print('  RESULT: ${outcome.outcomeString.toUpperCase()} '
        '(conf ${(outcome.confidence * 100).toStringAsFixed(0)}%)  '
        'ground-truth: ${gtPositive ? 'POSITIVE' : 'NEGATIVE'}');
    print('  landmarks: M=${res.debug['magenta']} C=${res.debug['cyan']} '
        'Y=${res.debug['stripYellow']} O=${res.debug['orange']}');
    print('  reactiveRow(work)=${res.debug['reactiveRow']}');
    print('  strip patchPitch=${(res.debug['patchPitch'] as double).toStringAsFixed(1)} '
        'reactiveRow=${res.reactiveLineWellsFound}  workScale=${s.toStringAsFixed(3)}');

    for (var i = 0; i < 9; i++) {
      final det = res.wellCentresWork[i]; // working px
      final detOrig = [det[0] / s, det[1] / s];
      final gt = gtCentres[i];
      final dx = detOrig[0] - gt[0];
      final dy = detOrig[1] - gt[1];
      final err = _hypot(dx, dy);
      totalErr += err;
      totalPts++;
      final reading = res.readings[i];
      final cell = 'R${i ~/ 3 + 1}C${i % 3 + 1}';
      print('  $cell  det=(${detOrig[0].toStringAsFixed(0)},${detOrig[1].toStringAsFixed(0)})'
          '  gt=(${gt[0].toStringAsFixed(0)},${gt[1].toStringAsFixed(0)})'
          '  err=${err.toStringAsFixed(0)}px'
          '  S=${reading.saturation.toStringAsFixed(3)} H=${reading.hue.toStringAsFixed(0)}'
          '  ${reading.isReactive ? 'REACTIVE' : '-'}');
    }
  }
  print('\nMean placement error: ${(totalErr / totalPts).toStringAsFixed(1)} px '
      '(over $totalPts wells)');
}

List<List<double>> _gridCentres(Map<String, dynamic> corners, int rows, int cols) {
  List<double> tl = _pt(corners['tl']);
  List<double> tr = _pt(corners['tr']);
  List<double> br = _pt(corners['br']);
  List<double> bl = _pt(corners['bl']);
  final out = <List<double>>[];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final u = (c + 0.5) / cols;
      final v = (r + 0.5) / rows;
      final topX = tl[0] + u * (tr[0] - tl[0]);
      final topY = tl[1] + u * (tr[1] - tl[1]);
      final botX = bl[0] + u * (br[0] - bl[0]);
      final botY = bl[1] + u * (br[1] - bl[1]);
      out.add([topX + v * (botX - topX), topY + v * (botY - topY)]);
    }
  }
  return out;
}

List<double> _pt(dynamic p) => [(p[0] as num).toDouble(), (p[1] as num).toDouble()];

double _hypot(double a, double b) => (a * a + b * b) <= 0 ? 0 : _sqrt(a * a + b * b);
double _sqrt(double x) {
  var g = x;
  for (var i = 0; i < 40; i++) {
    g = 0.5 * (g + x / g);
  }
  return g;
}
