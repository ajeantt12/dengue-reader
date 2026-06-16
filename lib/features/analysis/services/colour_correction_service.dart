import 'package:image/image.dart' as img;
import '../../../core/constants/app_constants.dart';

class ColourCorrectionService {
  img.Image applyCorrection(img.Image input) {
    // 1. Locate reference patch
    // For now using simple crop based on constants
    final patchX = (input.width * AppConstants.referencePatchX).toInt();
    final patchY = (input.height * AppConstants.referencePatchY).toInt();
    final patchSize = (input.width * AppConstants.referencePatchSize).toInt();
    
    final patch = img.copyCrop(input, x: patchX, y: patchY, width: patchSize, height: patchSize);
    
    // 2. Compute average RGB
    double totalR = 0, totalG = 0, totalB = 0;
    int pixelCount = 0;
    
    for (final pixel in patch) {
      totalR += pixel.r;
      totalG += pixel.g;
      totalB += pixel.b;
      pixelCount++;
    }
    
    if (pixelCount == 0) return input;
    
    final avgR = totalR / pixelCount;
    final avgG = totalG / pixelCount;
    final avgB = totalB / pixelCount;
    
    // 3. Compute multipliers
    final corrR = AppConstants.referenceKnownRgb[0] / avgR;
    final corrG = AppConstants.referenceKnownRgb[1] / avgG;
    final corrB = AppConstants.referenceKnownRgb[2] / avgB;
    
    // 4. Apply correction
    final output = input.clone();
    for (final pixel in output) {
      pixel.r = (pixel.r * corrR).clamp(0, 255);
      pixel.g = (pixel.g * corrG).clamp(0, 255);
      pixel.b = (pixel.b * corrB).clamp(0, 255);
    }
    
    return output;
  }
}
