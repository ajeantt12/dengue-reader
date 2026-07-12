import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/history_provider.dart';
import '../services/csv_export_service.dart';
import 'widgets/test_record_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _showDataInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About saved data'),
        content: const Text(
          'Saved results and their images stay on this device through app '
          'updates — installing a newer APK over the existing app keeps all '
          'your data.\n\n'
          'Data is only lost if the app is uninstalled first (or its storage '
          'is cleared). You do not need to export before every update, but '
          'exporting now and then is a good backup habit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About saved data',
            onPressed: () => _showDataInfo(context),
          ),
          historyState.whenOrNull(
            data: (results) => results.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Export data + images',
                    onPressed: () => CsvExportService().exportAndShare(results),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
          historyState.whenOrNull(
            data: (results) => results.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear all',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all records?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(historyNotifierProvider.notifier).clearAll();
                      }
                    },
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text('No tests recorded yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.goNamed('capture'),
                    child: const Text('Take your first test'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final result = results[i];
              return TestRecordTile(
                result: result,
                onDelete: () {
                  ref.read(historyNotifierProvider.notifier).delete(result.id);
                },
                onTap: () => context.pushNamed('result', extra: result),
              );
            },
          );
        },
      ),
    );
  }
}
