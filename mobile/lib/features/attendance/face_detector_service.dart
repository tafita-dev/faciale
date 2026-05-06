import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class FaceDetectorService {
  final FaceDetector _faceDetector;

  FaceDetectorService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableLandmarks: true,
            enableClassification: true,
          ),
        );

  Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  Future<List<Face>> detectFacesFromInputImage(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }
bool isFaceValid(Face face) {
  final double pitch = face.headEulerAngleX ?? 0;
  final double yaw = face.headEulerAngleY ?? 0;

  // Valid if looking straight (within 15 degrees)
  return pitch.abs() < 15 && yaw.abs() < 15;
}

bool isLive(Face face) {
  final double? leftEye = face.leftEyeOpenProbability;
  final double? rightEye = face.rightEyeOpenProbability;

  // Basic blink detection: both eyes must have been detected as open at some point
  // For a real-time stream, we might want to track state changes,
  // but here we'll start with "eyes must be open" as a requirement for capture.
  if (leftEye == null || rightEye == null) return false;
  return leftEye > 0.5 && rightEye > 0.5;
}
Future<void> dispose() async {
  await _faceDetector.close();
}
}

