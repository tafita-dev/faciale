import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:faciale/features/attendance/face_detector_service.dart';

@GenerateMocks([FaceDetectorService])
import 'orientation_test.mocks.dart';

void main() {
  late MockFaceDetectorService mockFaceDetector;

  setUp(() {
    mockFaceDetector = MockFaceDetectorService();
  });

  test('orientation check should pass when face is centered', () async {
    final face = Face(
      boundingBox: Rect.fromLTWH(0, 0, 100, 100),
      landmarks: {},
      contours: {},
      headEulerAngleX: 0, // Pitch
      headEulerAngleY: 0, // Yaw
      headEulerAngleZ: 0,
    );

    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [face]);

    final faces = await mockFaceDetector.detectFaces('path');
    final isCentered = (faces.first.headEulerAngleX?.abs() ?? 0) < 15 &&
                       (faces.first.headEulerAngleY?.abs() ?? 0) < 15;

    expect(isCentered, isTrue);
  });

  test('orientation check should fail when face is looking away', () async {
    final face = Face(
      boundingBox: Rect.fromLTWH(0, 0, 100, 100),
      landmarks: {},
      contours: {},
      headEulerAngleX: 30, // Pitch
      headEulerAngleY: 30, // Yaw
      headEulerAngleZ: 0,
    );

    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [face]);

    final faces = await mockFaceDetector.detectFaces('path');
    final isCentered = (faces.first.headEulerAngleX?.abs() ?? 0) < 15 &&
                       (faces.first.headEulerAngleY?.abs() ?? 0) < 15;

    expect(isCentered, isFalse);
  });
}
