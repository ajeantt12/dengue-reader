// Prints detector and classification diagnostics for one captured plate photo.
//
// Usage:
//   dart run tool/analyse_capture.dart path/to/capture.jpg

import 'dart:io';

import 'package:image/image.dart' as img;

import '../lib/features/analysis/services/plate_detector_service.dart';
import '../lib/features/analysis/services/result_calculator.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/analyse_capture.dart path/to/capture.jpg',
    );
    exitCode = 64;
    return;
  }

  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('Capture not found: ${file.path}');
    exitCode = 66;
    return;
  }

  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    stderr.writeln('Could not decode: ${file.path}');
    exitCode = 65;
    return;
  }

  final detection = PlateDetectorService().analyse(image, assertQuality: false);
  final result = ResultCalculator().calculate(detection.readings);

  print(
    'Outcome: ${result.outcomeString} '
    '(${(result.confidence * 100).toStringAsFixed(0)}%)',
  );
  print('Reactive wells: ${result.reactiveDotIds.toList()..sort()}');
  print('Detected row-1 anchors: ${detection.reactiveLineWellsFound}');
  for (final reading in detection.readings) {
    print(
      '${reading.dotId}: '
      'S=${(reading.saturation * 100).toStringAsFixed(1)}% '
      'H=${reading.hue.toStringAsFixed(1)} '
      'V=${(reading.value * 100).toStringAsFixed(1)}%',
    );
  }
}
