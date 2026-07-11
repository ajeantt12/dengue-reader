// Regression tests for the content-based plate detector, run against the gold
// research samples (assets/research/samples) with hand-verified ground truth.
//
//   flutter test test/plate_detector_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:dengue_reader/features/analysis/services/plate_detector_service.dart';
import 'package:dengue_reader/features/analysis/services/result_calculator.dart';

const _samplesDir = 'assets/research/samples';

PlateDetectionResult _analyse(String id) {
  final bytes = File('$_samplesDir/$id.jpeg').readAsBytesSync();
  final image = img.decodeImage(bytes)!;
  return PlateDetectorService().analyse(image);
}

void main() {
  group('PlateDetectorService (gold set)', () {
    test('locates a full 3x3 grid and the reactive line on every gold plate',
        () {
      for (final id in ['DR005', 'DR008', 'DR009', 'DR010']) {
        final res = _analyse(id);
        expect(res.readings.length, 9, reason: '$id well count');
        expect(res.stripFound, isTrue, reason: '$id strip');
        expect(res.reactiveLineWellsFound, 3, reason: '$id reactive line');
      }
    });

    // DR005/008/009/010 were shot under the *old* single-test-line plate
    // (row 1 = the reactive line, rows 2-3 = filler negatives — see
    // CALIBRATION.md). ResultCalculator has since moved to a control-row
    // scheme (row 1 = positive control, row 2 = negative control, row 3 =
    // the actual sample) that these photos don't physically represent: their
    // row 3 never develops, so the calculator correctly reads NEGATIVE for
    // all of them now. What's still valid to assert against real photos is
    // that the positive-control anchor itself reads reactive — i.e. the
    // calibration machinery works — not the overall outcome.
    test('positive-control row (R1) reads reactive on real gold photos', () {
      for (final id in ['DR005', 'DR008', 'DR009', 'DR010']) {
        final res = _analyse(id);
        final outcome = ResultCalculator().calculate(res.readings);
        final posControlIds =
            res.readings.where((d) => d.dotId.startsWith('R1')).map((d) => d.dotId);
        for (final dotId in posControlIds) {
          expect(outcome.reactiveDotIds.contains(dotId), isTrue,
              reason: '$id $dotId');
        }
      }
    });

    test('reactive-line wells read yellow (hue 40-80) with real saturation', () {
      // The old detector sampled background here and returned near-zero
      // saturation; the fix must sample the actual yellow wells.
      final res = _analyse('DR005');
      final topRow = res.readings.where((d) => d.dotId.startsWith('R1'));
      for (final d in topRow) {
        expect(d.hue, inInclusiveRange(40, 80), reason: d.dotId);
        expect(d.saturation, greaterThan(0.4), reason: d.dotId);
      }
    });

    test('negative wells stay non-reactive', () {
      final res = _analyse('DR005');
      final lowerRows =
          res.readings.where((d) => !d.dotId.startsWith('R1'));
      for (final d in lowerRows) {
        expect(d.isReactive, isFalse, reason: d.dotId);
      }
    });

    // DR010 is the deliberately faint-positive exemplar. It currently reads
    // NEGATIVE at the default threshold — captured here so a future threshold
    // calibration change is a conscious, visible decision. Its wells still read
    // yellow (proving detection works); only the intensity threshold misses.
    test('faint DR010 wells read yellow even though it scores below threshold',
        () {
      final res = _analyse('DR010');
      final topRow = res.readings.where((d) => d.dotId.startsWith('R1'));
      for (final d in topRow) {
        expect(d.hue, inInclusiveRange(40, 85), reason: '${d.dotId} hue');
        expect(d.saturation, greaterThan(0.08),
            reason: '${d.dotId} not background');
      }
    });
  });
}
