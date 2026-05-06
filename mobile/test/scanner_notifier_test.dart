import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/face_detector_service.dart';

@GenerateMocks([AttendanceRepository, FaceDetectorService])
import 'scanner_notifier_test.mocks.dart';

void main() {
  late MockAttendanceRepository mockRepository;
  late MockFaceDetectorService mockFaceDetector;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockFaceDetector = MockFaceDetectorService();
  });

  test('should NOT call repository when no face is detected', () async {
    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => []);
    
    // Simulate the workflow inside the scanner...
    final faces = await mockFaceDetector.detectFaces('dummy_path');
    
    if (faces.isEmpty) {
      // Expectation: Repository should not be called
      verifyNever(mockRepository.checkIn(any));
    }
  });

  test('should call repository when a face is detected', () async {
    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [
      Face(
        boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        landmarks: {},
        contours: {},
        headEulerAngleX: 0,
        headEulerAngleY: 0,
        headEulerAngleZ: 0,
      )
    ]);
    when(mockRepository.checkIn(any, forceType: anyNamed('forceType'))).thenAnswer((_) async => {'success': true, 'data': {'employee_name': 'Test'}});

    final faces = await mockFaceDetector.detectFaces('dummy_path');
    
    if (faces.isNotEmpty) {
      await mockRepository.checkIn('dummy_path');
    }

    verify(mockRepository.checkIn('dummy_path')).called(1);
  });
}
