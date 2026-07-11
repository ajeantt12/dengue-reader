import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/analysis_provider.dart';
import '../../../shared/models/test_result.dart';
import '../../../core/exceptions/analysis_exception.dart';
import 'widgets/processing_animation.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const AnalysisScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analysisNotifierProvider.notifier).analyzeImage(widget.imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisNotifierProvider);

    ref.listen<AsyncValue<TestResult?>>(analysisNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        context.pushReplacementNamed('result', extra: next.value);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: analysisState.when(
          loading: () => _buildProcessing(),
          data: (_) => _buildProcessing(), // still navigating
          error: (err, _) => _buildError(context, err),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProcessingAnimation(),
          SizedBox(height: 32),
          Text(
            'Analysing dots…',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Applying colour correction and reading dot saturation',
            style: TextStyle(fontSize: 14, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final (icon, title, message, tips) = _parseError(error);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.white38),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 18, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.goNamed('capture'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.goNamed('history'),
            child: const Text('View past results', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  (IconData, String, String, List<String>) _parseError(Object error) {
    if (error is ImageTooDataarkException) {
      return (
        Icons.brightness_2,
        'Image too dark',
        error.userMessage,
        error.tips,
      );
    }
    if (error is ImageOverexposedException) {
      return (
        Icons.brightness_7,
        'Too much glare',
        error.userMessage,
        error.tips,
      );
    }
    if (error is PlateNotDetectedException) {
      return (
        Icons.crop_free,
        'Plate not detected',
        error.userMessage,
        error.tips,
      );
    }
    if (error is ImageDecodeException) {
      return (
        Icons.broken_image_outlined,
        'Image error',
        error.userMessage,
        error.tips,
      );
    }
    return (
      Icons.error_outline,
      'Something went wrong',
      'Please try capturing the image again.',
      const <String>[],
    );
  }
}
