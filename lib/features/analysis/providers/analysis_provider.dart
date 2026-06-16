import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../services/colour_correction_service.dart';
import '../services/dot_detector_service.dart';
import '../services/result_calculator.dart';
import '../../../shared/models/test_result.dart';
import '../../../features/history/providers/history_provider.dart';

part 'analysis_provider.g.dart';

@riverpod
class AnalysisNotifier extends _$AnalysisNotifier {
  @override
  FutureOr<TestResult?> build() => null;

  Future<void> analyzeImage(String imagePath) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final corrected = ColourCorrectionService().applyCorrection(image);
      final readings = DotDetectorService().detectDots(corrected);
      final result = ResultCalculator().calculate(readings);

      final testResult = TestResult(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        outcome: result.outcomeString,
        confidence: result.confidence,
        dotReadings: readings,
        imagePath: imagePath,
      );

      // Persist to Hive
      await ref.read(historyNotifierProvider.notifier).save(testResult);

      return testResult;
    });
  }
}
