import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_constants.dart';

part 'camera_provider.g.dart';

/// Torch control mode: [auto] follows the ambient-brightness heuristic,
/// [on]/[off] are user-forced states that suspend the heuristic.
enum TorchMode { auto, on, off }

@riverpod
class CameraControllerNotifier extends _$CameraControllerNotifier {
  CameraController? _controller;
  bool _isStreaming = false;
  TorchMode _torchMode = TorchMode.auto;
  bool _torchOn = false;
  DateTime? _lastTorchSwitch;

  TorchMode get torchMode => _torchMode;
  bool get isTorchOn => _torchOn;

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

  /// Stop the stream and capture a still image. Leaves the torch mode
  /// untouched but switches the physical torch off afterwards: this provider
  /// isn't disposed when navigating to the analysis screen (the camera route
  /// stays underneath it in the stack), so without this the flash would stay
  /// lit — pointed at nothing — for as long as the user is on the analysis
  /// or error screen.
  Future<XFile> captureImage() async {
    if (_controller == null) throw StateError('Camera not ready');
    await _stopStream();
    final file = await _controller!.takePicture();
    await _setTorch(false);
    return file;
  }

  /// User-driven torch control. Setting [TorchMode.on] or [TorchMode.off]
  /// forces the flash and suspends the auto-brightness heuristic;
  /// [TorchMode.auto] hands control back to [_autoTorch].
  Future<void> setTorchMode(TorchMode mode) async {
    _torchMode = mode;
    switch (mode) {
      case TorchMode.on:
        await _setTorch(true);
      case TorchMode.off:
        await _setTorch(false);
      case TorchMode.auto:
        break;
    }
  }

  Future<void> _setTorch(bool on) async {
    if (_controller == null || _torchOn == on) return;
    _torchOn = on;
    _lastTorchSwitch = DateTime.now();
    try {
      await _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
  }

  /// Auto-brightness torch heuristic. Only ever switches the torch ON when
  /// ambient brightness drops below [AppConstants.torchOnThreshold] — it
  /// never auto-switches it back off. The torch's own light overwhelms the
  /// brightness signal (a lit frame reads near-1.0), so any auto-off rule
  /// driven by that same signal creates a feedback loop: torch on → frame
  /// reads bright → torch off → frame reads dark again → torch on — an
  /// endless strobe. Once auto-torch turns it on, only a manual toggle
  /// (see [setTorchMode]) turns it back off.
  void _autoTorch(double brightness) {
    if (_controller == null || _torchMode != TorchMode.auto || _torchOn) {
      return;
    }
    final now = DateTime.now();
    if (_lastTorchSwitch != null &&
        now.difference(_lastTorchSwitch!) < AppConstants.torchSwitchCooldown) {
      return;
    }
    if (brightness < AppConstants.torchOnThreshold) {
      _setTorch(true);
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
