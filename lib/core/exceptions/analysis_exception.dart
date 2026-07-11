class DengueAnalysisException implements Exception {
  final String userMessage;

  /// Short, actionable follow-ups shown as a bulleted list below
  /// [userMessage] — e.g. "Avoid direct sunlight", "Try without flash".
  final List<String> tips;
  final String technicalDetail;

  const DengueAnalysisException(this.userMessage,
      {this.tips = const [], this.technicalDetail = ''});

  @override
  String toString() => userMessage;
}

class ImageDecodeException extends DengueAnalysisException {
  const ImageDecodeException()
      : super('Could not read the image.',
            tips: const ['Please try again'],
            technicalDetail: 'Failed to decode captured image bytes');
}

class ImageTooDataarkException extends DengueAnalysisException {
  const ImageTooDataarkException()
      : super('Image is too dark.',
            tips: const ['Move to a brighter area', 'Enable flash'],
            technicalDetail: 'Average pixel value below darkness threshold');
}

class ImageOverexposedException extends DengueAnalysisException {
  const ImageOverexposedException()
      : super('Image is overexposed.',
            tips: const [
              'Avoid direct sunlight on the plate',
              'Try capturing without flash',
            ],
            technicalDetail: 'All dots near-white, saturation < 0.02');
}

class PlateNotDetectedException extends DengueAnalysisException {
  const PlateNotDetectedException()
      : super('Test plate not detected.',
            tips: const ['Align the plate inside the frame', 'Try again'],
            technicalDetail: 'Dot region variance too low — uniform image');
}
