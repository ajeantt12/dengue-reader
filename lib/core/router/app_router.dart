import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/analysis/presentation/analysis_screen.dart';
import '../../features/capture/presentation/capture_screen.dart'
    show CaptureScreen, CameraViewfinderScreen;
import '../../features/history/presentation/history_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../shared/models/test_result.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraViewfinderScreen(),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) => AnalysisScreen(
          imagePath: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => ResultScreen(
          result: state.extra as TestResult,
        ),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}
