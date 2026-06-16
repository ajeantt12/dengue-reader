import 'package:image/image.dart' as img;
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/analysis_exception.dart';
import '../../../shared/models/dot_reading.dart';

class DotDetectorService {
  List<DotReading> detectDots(img.Image correctedImage) {
    final readings = <DotReading>[];

    for (final entry in AppConstants.dotCentres.entries) {
      final dotId = entry.key;
      final centre = entry.value;

      final cx = (centre[0] * correctedImage.width).toInt();
      final cy = (centre[1] * correctedImage.height).toInt();
      final radius = AppConstants.dotRadius.toInt();

      double totalR = 0, totalG = 0, totalB = 0;
      int count = 0;

      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          if (dx * dx + dy * dy > radius * radius) continue;
          final px = cx + dx;
          final py = cy + dy;
          if (px < 0 || py < 0 || px >= correctedImage.width || py >= correctedImage.height) continue;

          final pixel = correctedImage.getPixel(px, py);
          totalR += pixel.r.toDouble();
          totalG += pixel.g.toDouble();
          totalB += pixel.b.toDouble();
          count++;
        }
      }

      if (count == 0) continue;

      final avgR = (totalR / count).round().clamp(0, 255);
      final avgG = (totalG / count).round().clamp(0, 255);
      final avgB = (totalB / count).round().clamp(0, 255);
      final hsv = _rgbToHsv(avgR, avgG, avgB);

      readings.add(DotReading(
        dotId: dotId,
        hue: hsv[0],
        saturation: hsv[1],
        value: hsv[2],
        rawR: avgR,
        rawG: avgG,
        rawB: avgB,
      ));
    }

    _assertImageQuality(readings);
    return readings;
  }

  void _assertImageQuality(List<DotReading> readings) {
    if (readings.isEmpty) throw const PlateNotDetectedException();

    final avgValue = readings.map((d) => d.value).reduce((a, b) => a + b) / readings.length;
    final avgSat = readings.map((d) => d.saturation).reduce((a, b) => a + b) / readings.length;

    // Image too dark — all dots are very dark
    if (avgValue < 0.12) throw const ImageTooDataarkException();

    // Image overexposed — all dots are near-white with zero saturation
    if (avgValue > 0.92 && avgSat < 0.03) throw const ImageOverexposedException();

    // Plate not aligned — all dots look identical (near-zero variance in saturation)
    if (readings.length >= 4) {
      final mean = avgSat;
      final variance = readings
              .map((d) => (d.saturation - mean) * (d.saturation - mean))
              .reduce((a, b) => a + b) /
          readings.length;
      if (variance < 0.0005 && mean < 0.08) throw const PlateNotDetectedException();
    }
  }

  // Returns [H(0–360), S(0–1), V(0–1)]
  List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final max = [rf, gf, bf].reduce((a, c) => a > c ? a : c);
    final min = [rf, gf, bf].reduce((a, c) => a < c ? a : c);
    final delta = max - min;

    double h = 0;
    if (delta != 0) {
      if (max == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (max == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
      if (h < 0) h += 360;
    }

    return [h, max == 0 ? 0.0 : delta / max, max];
  }
}
