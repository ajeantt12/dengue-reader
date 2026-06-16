import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/test_result.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/theme/app_colors.dart';

class TestRecordTile extends StatelessWidget {
  final TestResult result;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TestRecordTile({
    super.key,
    required this.result,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(result.timestamp);
    final status = switch (result.outcome) {
      'positive' => TestStatus.positive,
      'negative' => TestStatus.negative,
      _ => TestStatus.invalid,
    };
    final pct = (result.confidence * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          result.outcome == 'positive' ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
          color: result.outcome == 'positive' ? AppColors.positive : AppColors.negative,
          size: 36,
        ),
        title: StatusBadge(status: status),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$dateStr  ·  Confidence $pct%', style: const TextStyle(fontSize: 12)),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.black38,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
