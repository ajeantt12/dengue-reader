import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_constants.dart';

part 'camera_provider.g.dart';

@riverpod
class CameraControllerNotifier extends _$CameraControllerNotifier {
  CameraController? _controller;
  bool _isStreaming = false;

  @override
  FutureOr<CameraController?> build() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();
    _controller = controller;

    await controller.setExposureMode(ExposureMode.auto);
    await controller.setFocusMode(FocusMode.auto);

    ref.onDispose(() {
      _stopStream();
      _controller?.dispose();
    });

    return controller;
  }

  /// Start the image stream and call [onBrightness] with a 0–1 brightness value.
  /// Safe to call multiple times — ignored if already streaming.
  Future<void> startBrightnessStream(void Function(double brightness) onBrightness) async {
    if (_controller == null || _isStreaming) return;
    try {
      _isStreaming = true;
      await _controller!.startImageStream((image) {
        final b = _sampleBrightness(image);
        onBrightness(b);
        _autoTorch(b);
      });
    } catch (_) {
      _isStreaming = false;
    }
  }

  Future<void> _stopStream() async {
    if (_controller == null || !_isStreaming) return;
    try {
      _isStreaming = false;
      await _controller!.stopImageStream();
    } catch (_) {}
  }

  /// Stop the stream, capture a still image, restart the stream.
  Future<XFile> captureImage() async {
    if (_controller == null) throw StateError('Camera not ready');
    await _stopStream();
    final file = await _controller!.takePicture();
    return file;
  }

  Future<void> toggleTorch(bool enabled) async {
    if (_controller == null) return;
    await _controller!.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
  }

  void _autoTorch(double brightness) {
    if (_controller == null) return;
    if (brightness < AppConstants.brightnessThreshold) {
      _controller!.setFlashMode(FlashMode.torch);
    } else {
      _controller!.setFlashMode(FlashMode.off);
    }
  }

  /// Sample image brightness from the first plane (Y for YUV, B for BGRA).
  /// Skips pixels for performance.
  double _sampleBrightness(CameraImage image) {
    try {
      final format = image.format.group;
      if (format == ImageFormatGroup.yuv420) {
        final yBytes = image.planes[0].bytes;
        int total = 0;
        int count = 0;
        for (int i = 0; i < yBytes.length; i += 64) {
          total += yBytes[i];
          count++;
        }
        return count > 0 ? (total / count) / 255.0 : 1.0;
      } else if (format == ImageFormatGroup.bgra8888) {
        final bytes = image.planes[0].bytes;
        int total = 0;
        int count = 0;
        for (int i = 0; i < bytes.length; i += 256) {
          final b = bytes[i];
          final g = bytes[i + 1];
          final r = bytes[i + 2];
          // BT.601 luma
          total += (0.114 * b + 0.587 * g + 0.299 * r).round();
          count++;
        }
        return count > 0 ? (total / count) / 255.0 : 1.0;
      }
    } catch (_) {}
    return 1.0;
  }
}
