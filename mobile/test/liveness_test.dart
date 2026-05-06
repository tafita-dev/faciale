import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:faciale/features/attendance/face_detector_service.dart';

@GenerateMocks([FaceDetectorService])
import 'liveness_test.mocks.dart';

void main() {
  late MockFaceDetectorService mockFaceDetector;

  setUp(() {
    mockFaceDetector = MockFaceDetectorService();
  });

  test('liveness check should pass when eyes are open', () async {
    final face = Face(
      boundingBox: Rect.fromLTWH(0, 0, 100, 100),
      landmarks: {},
      contours: {},
      headEulerAngleX: 0,
      headEulerAngleY: 0,
      headEulerAngleZ: 0,
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.9,
    );

    final service = FaceDetectorService();
    expect(service.isLive(face), isTrue);
  });

  test('liveness check should fail when eyes are closed', () async {
    final face = Face(
      boundingBox: Rect.fromLTWH(0, 0, 100, 100),
      landmarks: {},
      contours: {},
      headEulerAngleX: 0,
      headEulerAngleY: 0,
      headEulerAngleZ: 0,
      leftEyeOpenProbability: 0.1,
      rightEyeOpenProbability: 0.1,
    );

    final service = FaceDetectorService();
    expect(service.isLive(face), isFalse);
  });
}
