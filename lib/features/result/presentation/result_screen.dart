import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/test_result.dart';
import '../../../shared/widgets/app_button.dart';
import 'widgets/result_card.dart';
import 'widgets/dot_grid_display.dart';
import 'widgets/confidence_indicator.dart';

class ResultScreen extends ConsumerWidget {
  final TestResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(result.timestamp);

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
              ResultCard(result: result),
              const SizedBox(height: 24),
              ConfidenceIndicator(confidence: result.confidence),
              const SizedBox(height: 24),
              DotGridDisplay(readings: result.dotReadings),
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
            ],
          ),
        ),
      ),
    );
  }
}
