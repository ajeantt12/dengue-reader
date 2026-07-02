import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/camera_provider.dart';
import '../services/demo_service.dart';
import 'widgets/capture_button.dart';
import 'widgets/lighting_indicator.dart';
import 'widgets/viewfinder_overlay.dart';

// ─── Home screen ────────────────────────────────────────────────────────────

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DengueReader'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.pushNamed('history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header illustration / icon
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.biotech, size: 72, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Dengue Rapid Test Reader',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'How would you like to add the test plate image?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Take photo card
              _OptionCard(
                icon: Icons.camera_alt_rounded,
                color: AppColors.primary,
                title: 'Take a Photo',
                subtitle: 'Use your camera to photograph the test plate',
                onTap: () => context.pushNamed('camera'),
              ),
              const SizedBox(height: 16),
              // Upload card
              _OptionCard(
                icon: Icons.photo_library_rounded,
                color: AppColors.secondary,
                title: 'Upload from Gallery',
                subtitle: 'Select an existing photo from your device',
                onTap: () => _pickFromGallery(context),
              ),
              const SizedBox(height: 16),
              // Demo mode
              OutlinedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Demo Mode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showDemoSheet(context),
              ),
              const Spacer(),
              Text(
                'Align the test plate clearly in frame for best results.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked != null && context.mounted) {
      context.pushNamed('analysis', extra: picked.path);
    }
  }

  void _showDemoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Demo Mode',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Simulate a result without scanning a plate.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54)),
            const SizedBox(height: 24),
            _DemoTile(
              icon: Icons.warning_amber_rounded,
              color: AppColors.positive,
              label: 'Positive Result',
              subtitle: 'IgM reactive — dengue antibodies detected',
              onTap: () {
                Navigator.pop(context);
                final result = DemoService().buildDemo(DemoScenario.positive);
                context.pushNamed('result', extra: result);
              },
            ),
            const SizedBox(height: 12),
            _DemoTile(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.negative,
              label: 'Negative Result',
              subtitle: 'Control reactive, all test dots clear',
              onTap: () {
                Navigator.pop(context);
                final result = DemoService().buildDemo(DemoScenario.negative);
                context.pushNamed('result', extra: result);
              },
            ),
            const SizedBox(height: 12),
            _DemoTile(
              icon: Icons.help_outline_rounded,
              color: AppColors.invalid,
              label: 'Invalid Result',
              subtitle: 'Control dot not reactive — test failed',
              onTap: () {
                Navigator.pop(context);
                final result = DemoService().buildDemo(DemoScenario.invalid);
                context.pushNamed('result', extra: result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Camera viewfinder screen ────────────────────────────────────────────────

/// Renders [CameraPreview] scaled to fill its parent (cover), preserving the
/// sensor's native aspect ratio instead of letting the Stack stretch it to
/// fit the device screen — the cause of the distorted preview seen on
/// devices like the Pixel 7a, whose sensor aspect ratio differs from the
/// screen's.
class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final previewAspect = controller.value.aspectRatio;
        var scale = size.aspectRatio * previewAspect;
        if (scale < 1) scale = 1 / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: AspectRatio(
                aspectRatio: previewAspect,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CameraViewfinderScreen extends ConsumerStatefulWidget {
  const CameraViewfinderScreen({super.key});

  @override
  ConsumerState<CameraViewfinderScreen> createState() =>
      _CameraViewfinderScreenState();
}

class _CameraViewfinderScreenState
    extends ConsumerState<CameraViewfinderScreen> {
  int _countdown = 0;
  Timer? _timer;
  double _brightness = 0.5;
  bool _monitoringStarted = false;
  TorchMode _torchMode = TorchMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMonitoring());
  }

  Future<void> _startMonitoring() async {
    if (_monitoringStarted) return;
    final cameraState = ref.read(cameraControllerNotifierProvider);
    if (cameraState.value == null) return;
    _monitoringStarted = true;
    await ref
        .read(cameraControllerNotifierProvider.notifier)
        .startBrightnessStream((b) {
      if (mounted) setState(() => _brightness = b);
    });
  }

  void _cycleTorchMode() {
    final next = switch (_torchMode) {
      TorchMode.auto => TorchMode.on,
      TorchMode.on => TorchMode.off,
      TorchMode.off => TorchMode.auto,
    };
    setState(() => _torchMode = next);
    ref.read(cameraControllerNotifierProvider.notifier).setTorchMode(next);
  }

  void _startCapture() {
    setState(() => _countdown = 3);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      HapticFeedback.mediumImpact();
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        setState(() => _countdown = 0);
        await _takePicture();
      }
    });
  }

  Future<void> _takePicture() async {
    try {
      final image = await ref
          .read(cameraControllerNotifierProvider.notifier)
          .captureImage();
      if (mounted) context.pushNamed('analysis', extra: image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerNotifierProvider);

    ref.listen(cameraControllerNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null && !_monitoringStarted) {
        _startMonitoring();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraState.when(
        data: (controller) {
          if (controller == null) {
            return const Center(
              child: Text('No camera found',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              _CoverCameraPreview(controller: controller),
              ViewfinderOverlay(brightness: _brightness),
              if (_countdown > 0)
                Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                    ),
                  ),
                ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
              // Lighting indicator
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(child: LightingIndicator(brightness: _brightness)),
              ),
              // Torch toggle (auto / on / off)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    switch (_torchMode) {
                      TorchMode.auto => Icons.flash_auto,
                      TorchMode.on => Icons.flash_on,
                      TorchMode.off => Icons.flash_off,
                    },
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Flash: ${_torchMode.name}',
                  onPressed: _cycleTorchMode,
                ),
              ),
              // Capture button
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    CaptureButton(countdown: _countdown, onTap: _startCapture),
                    const SizedBox(height: 12),
                    const Text('Tap to capture',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Starting camera…',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                const Text('Camera unavailable',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$err',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(cameraControllerNotifierProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
