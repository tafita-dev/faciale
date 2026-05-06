import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enroll_camera_screen.dart';

// Le provider qui gère la logique de capture
final capturePhotoProvider = Provider<Future<String?> Function(BuildContext)>((ref) {
  return (context) async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const EnrollCameraScreen()),
    );
  };
});