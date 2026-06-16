import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TestStatus { positive, negative, invalid }

class StatusBadge extends StatelessWidget {
  final TestStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case TestStatus.positive:
        color = AppColors.positive;
        label = 'POSITIVE';
        break;
      case TestStatus.negative:
        color = AppColors.negative;
        label = 'NEGATIVE';
        break;
      case TestStatus.invalid:
        color = AppColors.invalid;
        label = 'INVALID';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
