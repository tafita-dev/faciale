import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  late final FaceDetector _faceDetector;

  FaceDetectorService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode:
            FaceDetectorMode.accurate,

        enableLandmarks: true,

        enableContours: true,

        enableClassification: true,

        enableTracking: true,

        minFaceSize: 0.1,
      ),
    );
  }

  Future<List<Face>> detectFaces(
    String imagePath,
  ) async {
    try {
      final inputImage =
          InputImage.fromFilePath(
            imagePath,
          );

      return await _faceDetector
          .processImage(inputImage);
    } catch (e) {
      return [];
    }
  }

  Future<List<Face>>
  detectFacesFromInputImage(
    InputImage inputImage,
  ) async {
    try {
      return await _faceDetector
          .processImage(inputImage);
    } catch (e) {
      return [];
    }
  }

  bool isFaceValid(Face face) {
    final pitch =
        face.headEulerAngleX ?? 0;

    final yaw =
        face.headEulerAngleY ?? 0;

    return pitch.abs() < 15 &&
        yaw.abs() < 15;
  }

  bool isLive(Face face) {
    final leftEye =
        face.leftEyeOpenProbability;

    final rightEye =
        face.rightEyeOpenProbability;

    if (leftEye == null ||
        rightEye == null) {
      return false;
    }

    return leftEye > 0.4 &&
        rightEye > 0.4;
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

final faceDetectorServiceProvider =
    Provider<FaceDetectorService>((ref) {
      final service =
          FaceDetectorService();

      ref.onDispose(() async {
        await service.dispose();
      });

      return service;
    });