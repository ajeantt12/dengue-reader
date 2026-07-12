import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../services/plate_detector_service.dart';
import '../services/result_calculator.dart';
import '../../../core/exceptions/analysis_exception.dart';
import '../../../shared/models/test_result.dart';
import '../../../features/history/providers/history_provider.dart';

part 'analysis_provider.g.dart';

@riverpod
class AnalysisNotifier extends _$AnalysisNotifier {
  @override
  FutureOr<TestResult?> build() => null;

  Future<void> analyzeImage(
    String imagePath, {
    int wellsPerRow = PlateDetectorService.defaultGridCols,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw const ImageDecodeException();

      // Locate the plate/strip and sample the wells by scanning the whole
      // bright frame — no fixed template positions. Columns (wells per row)
      // come from the user's pre-capture setting; rows are fixed at three.
      final detection =
          PlateDetectorService().analyse(image, gridCols: wellsPerRow);
      final readings = detection.readings;
      final result = ResultCalculator().calculate(readings);

      final id = const Uuid().v4();
      // Copy the capture into persistent app storage. Camera shots land in an
      // OS-purgeable temp dir and gallery picks live outside the app, so the
      // original path can vanish; a copy under the app's documents dir keeps
      // the image available for history review and data export.
      final storedPath = await _persistImage(imagePath, id);

      final testResult = TestResult(
        id: id,
        timestamp: DateTime.now(),
        outcome: result.outcomeString,
        confidence: result.confidence,
        dotReadings: readings,
        imagePath: storedPath,
      );

      // Persist to Hive
      await ref.read(historyNotifierProvider.notifier).save(testResult);

      return testResult;
    });
  }

  /// Copies [sourcePath] into `<app documents>/captures/<id><ext>` and returns
  /// the new path. Falls back to the original path if the copy fails, so a
  /// storage hiccup never loses the analysis itself.
  Future<String> _persistImage(String sourcePath, String id) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'captures'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final ext = p.extension(sourcePath);
      final dest = p.join(dir.path, '$id${ext.isEmpty ? '.jpg' : ext}');
      await File(sourcePath).copy(dest);
      return dest;
    } catch (_) {
      return sourcePath;
    }
  }
}
