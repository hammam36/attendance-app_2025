import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class GoogleMlKit {
  static FaceDetector get vision {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    return FaceDetector(options: options);
  }
}