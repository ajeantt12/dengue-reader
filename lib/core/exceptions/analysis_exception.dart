class DengueAnalysisException implements Exception {
  final String userMessage;
  final String technicalDetail;

  const DengueAnalysisException(this.userMessage, {this.technicalDetail = ''});

  @override
  String toString() => userMessage;
}

class ImageDecodeException extends DengueAnalysisException {
  const ImageDecodeException()
      : super('Could not read the image. Please try again.',
            technicalDetail: 'Failed to decode captured image bytes');
}

class ImageTooDataarkException extends DengueAnalysisException {
  const ImageTooDataarkException()
      : super('Image is too dark.\nMove to a brighter area or enable flash.',
            technicalDetail: 'Average pixel value below darkness threshold');
}

class ImageOverexposedException extends DengueAnalysisException {
  const ImageOverexposedException()
      : super('Image is overexposed.\nAvoid direct sunlight on the plate.',
            technicalDetail: 'All dots near-white, saturation < 0.02');
}

class PlateNotDetectedException extends DengueAnalysisException {
  const PlateNotDetectedException()
      : super('Test plate not detected.\nAlign the plate inside the frame and try again.',
            technicalDetail: 'Dot region variance too low — uniform image');
}
