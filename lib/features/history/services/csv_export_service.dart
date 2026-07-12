import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/test_result.dart';

class CsvExportService {
  String buildCsv(List<TestResult> results) {
    final dotIds = <String>{};
    for (final result in results) {
      for (final reading in result.dotReadings) {
        dotIds.add(reading.dotId);
      }
    }
    final sortedDotIds = dotIds.toList()..sort();

    final header = [
      'id',
      'timestamp',
      'outcome',
      'confidence',
      'is_flagged',
      'flag_note',
      for (final dotId in sortedDotIds) ...[
        '${dotId}_hue',
        '${dotId}_saturation',
        '${dotId}_value',
        '${dotId}_r',
        '${dotId}_g',
        '${dotId}_b',
      ],
    ];

    final rows = <List<dynamic>>[header];

    for (final result in results) {
      final readingsById = {for (final r in result.dotReadings) r.dotId: r};
      final row = [
        result.id,
        result.timestamp.toUtc().toIso8601String(),
        result.outcome,
        result.confidence,
        result.isFlagged,
        result.flagNote ?? '',
        for (final dotId in sortedDotIds) ...() {
          final reading = readingsById[dotId];
          if (reading == null) return ['', '', '', '', '', ''];
          return [
            reading.hue,
            reading.saturation,
            reading.value,
            reading.rawR,
            reading.rawG,
            reading.rawB,
          ];
        }(),
      ];
      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports the readings CSV plus every result's captured image, bundled into
  /// a single zip so the research team gets the images alongside the data.
  /// Images whose file no longer exists on disk (e.g. old results saved before
  /// captures were persisted) are simply skipped.
  Future<void> exportAndShare(List<TestResult> results) async {
    final csv = buildCsv(results);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'dengue_reader_export_$timestamp.zip';

    final archive = Archive();
    final csvBytes = utf8.encode(csv);
    archive.addFile(ArchiveFile('data.csv', csvBytes.length, csvBytes));

    for (final result in results) {
      final imageFile = File(result.imagePath);
      if (!await imageFile.exists()) continue;
      final bytes = await imageFile.readAsBytes();
      final ext = p.extension(result.imagePath);
      final entryName = 'images/${result.id}${ext.isEmpty ? '.jpg' : ext}';
      archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(zipBytes);

    await Share.shareXFiles([XFile(file.path)], fileNameOverrides: [fileName]);
  }
}
