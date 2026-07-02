import 'package:hive/hive.dart';
import 'dot_reading.dart';

part 'test_result.g.dart';

@HiveType(typeId: 0)
class TestResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String outcome; // 'positive', 'negative', 'invalid'

  @HiveField(3)
  final double confidence; // 0.0–1.0

  @HiveField(4)
  final List<DotReading> dotReadings;

  @HiveField(5)
  final String imagePath;

  @HiveField(6)
  final bool isFlagged;

  @HiveField(7)
  final String? flagNote;

  TestResult({
    required this.id,
    required this.timestamp,
    required this.outcome,
    required this.confidence,
    required this.dotReadings,
    required this.imagePath,
    this.isFlagged = false,
    this.flagNote,
  });

  TestResult copyWith({bool isFlagged = false, String? flagNote}) {
    return TestResult(
      id: id,
      timestamp: timestamp,
      outcome: outcome,
      confidence: confidence,
      dotReadings: dotReadings,
      imagePath: imagePath,
      isFlagged: isFlagged,
      flagNote: flagNote,
    );
  }
}
