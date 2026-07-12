import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    final existing = box.get(id);
    await box.delete(id);
    if (existing != null) await _deleteImageFile(existing.imagePath);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<TestResult>(_boxName);
    final records = box.values.toList();
    await box.clear();
    for (final r in records) {
      await _deleteImageFile(r.imagePath);
    }
    ref.invalidateSelf();
  }

  /// Deletes a stored capture, but only if it lives inside the app's own
  /// `captures/` directory — a gallery pick whose copy failed keeps its
  /// original path, and we must never delete the user's original photo.
  Future<void> _deleteImageFile(String imagePath) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final capturesDir = p.join(docs.path, 'captures');
      if (!p.isWithin(capturesDir, imagePath)) return;
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup; an orphaned image file is not worth failing on.
    }
  }

  Future<void> setFlag(String id, bool flagged, String? note) async {
    final box = await Hive.openBox<TestResult>(_boxName);
    final existing = box.get(id);
    if (existing == null) return;
    await box.put(id, existing.copyWith(isFlagged: flagged, flagNote: note));
    ref.invalidateSelf();
  }
}
