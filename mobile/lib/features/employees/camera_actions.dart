import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enroll_screen.dart';

final capturePhotoProvider = Provider<Future<String?> Function(BuildContext)>((ref) {
  return (context) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    return await showDialog<String>(
      context: context,
      builder: (context) => CameraPreviewDialog(camera: cameras.first),
    );
  };
});
