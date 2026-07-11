import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/test_result.dart';
import '../../../shared/widgets/app_button.dart';
import '../../analysis/services/result_calculator.dart';
import '../../history/providers/history_provider.dart';
import 'widgets/result_card.dart';
import 'widgets/dot_grid_display.dart';
import 'widgets/confidence_indicator.dart';

class ResultScreen extends ConsumerWidget {
  final TestResult result;

  const ResultScreen({super.key, required this.result});

  Future<void> _showFlagDialog(BuildContext context, WidgetRef ref, TestResult current) async {
    final controller = TextEditingController(text: current.flagNote ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(current.isFlagged ? 'Update flag' : 'Flag this result'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. visually positive but read as negative',
          ),
          maxLines: 3,
        ),
        actions: [
          if (current.isFlagged)
            TextButton(
              onPressed: () async {
                await ref.read(historyNotifierProvider.notifier).setFlag(current.id, false, null);
                if (ctx.mounted) Navigator.pop(ctx, false);
              },
              child: const Text('Remove flag'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(historyNotifierProvider.notifier)
          .setFlag(current.id, true, controller.text.trim().isEmpty ? null : controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyNotifierProvider);
    final current = historyState.maybeWhen(
      data: (results) => results.where((r) => r.id == result.id).firstOrNull,
      orElse: () => null,
    ) ?? result;

    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(current.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Result'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => context.goNamed('capture'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(dateStr, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              ResultCard(result: current),
              const SizedBox(height: 24),
              ConfidenceIndicator(confidence: current.confidence),
              const SizedBox(height: 24),
              DotGridDisplay(
                readings: current.dotReadings,
                // Recomputed rather than persisted: it's a pure function of
                // the stored readings, so this stays correct for history
                // entries too without a Hive schema change.
                reactiveDotIds: ResultCalculator()
                    .calculate(current.dotReadings)
                    .reactiveDotIds,
              ),
              if (current.isFlagged) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          current.flagNote?.isNotEmpty == true
                              ? current.flagNote!
                              : 'Flagged for review',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: 'New Test',
                onPressed: () => context.goNamed('capture'),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'View History',
                isPrimary: false,
                onPressed: () => context.pushNamed('history'),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: current.isFlagged ? 'Update Flag' : 'Flag Incorrect Result',
                isPrimary: false,
                onPressed: () => _showFlagDialog(context, ref, current),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
