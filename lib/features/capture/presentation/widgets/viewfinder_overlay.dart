import 'package:flutter/material.dart';

class ViewfinderOverlay extends StatelessWidget {
  // Ambient brightness (0.0-1.0) from the camera preview, used to pick
  // whichever guide artwork stays visible against the current scene —
  // dark line art on bright scenes, light line art on dim/backlit ones.
  final double brightness;

  const ViewfinderOverlay({super.key, this.brightness = 0.5});

  // Same threshold LightingIndicator uses to flag "dim" scenes.
  static const double _dimThreshold = 0.30;

  // The guide artwork bakes in the 3x3 dot grid plus the colour-strip box
  // beneath it, at a fixed 0.62 (roughly 5:8) width:height aspect ratio —
  // the guide rect must keep this ratio or the art will stretch.
  static const double _assetAspect = 0.62;

  // Fractional vertical bounds of the strip box within the artwork,
  // measured from the source PNG (~63.1%-85.2% down).
  static const double _stripBoxTop = 0.631;
  static const double _stripBoxBottom = 0.852;

  @override
  Widget build(BuildContext context) {
    final asset = brightness < _dimThreshold
        ? 'assets/overlay/plate_guide_white.png'
        : 'assets/overlay/plate_guide_black.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final rectWidth = width * 0.62;
        final rectHeight = rectWidth / _assetAspect;
        final rectTop = (height - rectHeight) / 2;
        final rectLeft = (width - rectWidth) / 2;

        return Stack(
          children: [
            // Darkened background with a hole for the plate + strip guide.
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: rectLeft,
                    top: rectTop,
                    width: rectWidth,
                    height: rectHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Guide artwork, swapped for scene brightness so the line art
            // stays visible against the camera feed.
            Positioned(
              left: rectLeft,
              top: rectTop,
              width: rectWidth,
              height: rectHeight,
              child: IgnorePointer(
                child: Image.asset(asset, fit: BoxFit.fill),
              ),
            ),
            // Colour-strip label, centred over the strip box drawn in the artwork
            Positioned(
              left: rectLeft,
              top: rectTop + rectHeight * _stripBoxTop,
              width: rectWidth,
              height: rectHeight * (_stripBoxBottom - _stripBoxTop),
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Place colour strip here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Instructions
            Positioned(
              top: rectTop - 40,
              left: 0,
              right: 0,
              child: const Text(
                'Align test plate within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
