import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../attendance/facial_scanner_widget.dart';

class EnrollCameraScreen extends ConsumerWidget {
  const EnrollCameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FacialScannerWidget(
            initialManualCapture: true,
            showModeToggle: true,
            onImageCaptured: (imagePath) async {
              Navigator.pop(context, imagePath);
            },
          ),
          // Close button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Instruction text
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(
              'center_your_face'.tr().toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
