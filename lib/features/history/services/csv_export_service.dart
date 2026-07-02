import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
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

  Future<void> exportAndShare(List<TestResult> results) async {
    final csv = buildCsv(results);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'dengue_reader_export_$timestamp.csv';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], fileNameOverrides: [fileName]);
  }
}
