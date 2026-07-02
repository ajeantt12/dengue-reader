import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/test_result.dart';

part 'history_provider.g.dart';

const _boxName = 'test_results';

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  FutureOr<List<TestResult>> build() async {
    final box = await Hive.openBox<TestResult>(_boxName);
    final results = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<void> save(TestResult result) async {
    final box = await Hive.openBox<TestResult>(_boxName);
    await box.put(result.id, result);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final box = await Hive.openBox<TestResult>(_boxName);
    await box.delete(id);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<TestResult>(_boxName);
    await box.clear();
    ref.invalidateSelf();
  }

  Future<void> setFlag(String id, bool flagged, String? note) async {
    final box = await Hive.openBox<TestResult>(_boxName);
    final existing = box.get(id);
    if (existing == null) return;
    await box.put(id, existing.copyWith(isFlagged: flagged, flagNote: note));
    ref.invalidateSelf();
  }
}
