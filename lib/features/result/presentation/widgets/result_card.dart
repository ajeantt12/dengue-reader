import 'package:flutter/material.dart';
import '../../../../shared/models/test_result.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/theme/app_colors.dart';

class ResultCard extends StatelessWidget {
  final TestResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color cardColor;
    IconData icon;
    switch (result.outcome) {
      case 'positive':
        cardColor = AppColors.positive.withValues(alpha: 0.1);
        icon = Icons.warning_amber_rounded;
        break;
      case 'negative':
        cardColor = AppColors.negative.withValues(alpha: 0.1);
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        cardColor = AppColors.invalid.withValues(alpha: 0.1);
        icon = Icons.help_outline_rounded;
    }

    final status = switch (result.outcome) {
      'positive' => TestStatus.positive,
      'negative' => TestStatus.negative,
      _ => TestStatus.invalid,
    };

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 64, color: _iconColor(result.outcome)),
            const SizedBox(height: 12),
            StatusBadge(status: status),
            const SizedBox(height: 8),
            Text(
              _headline(result.outcome),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(String outcome) {
    return switch (outcome) {
      'positive' => AppColors.positive,
      'negative' => AppColors.negative,
      _ => AppColors.invalid,
    };
  }

  String _headline(String outcome) {
    return switch (outcome) {
      'positive' => 'Dengue antibodies detected.\nPlease consult a doctor.',
      'negative' => 'No dengue antibodies detected.',
      _ => 'Test result is invalid.\nPlease repeat the test.',
    };
  }
}
