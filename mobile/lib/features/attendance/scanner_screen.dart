import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../employees/camera_provider.dart';
import 'scanner_state.dart';
import 'face_oval_painter.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Hide status bar and navigation bar for immersive view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await ref.read(camerasProvider.future);
    if (cameras.isEmpty) return;

    // Use front camera if available
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startScanning();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startScanning() {
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _attemptCapture();
    });
  }

  Future<void> _attemptCapture() async {
    final status = ref.read(scannerProvider).status;
    if (status != ScannerStatus.scanning) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        await ref.read(scannerProvider.notifier).processImage(image.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    // Listen for success to play sound
    ref.listen(scannerProvider, (previous, next) {
      if (next.status == ScannerStatus.success && (previous?.status != ScannerStatus.success)) {
        SystemSound.play(SystemSoundType.click);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_isInitialized && _controller != null)
            Center(
              child: CameraPreview(_controller!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Face Oval Overlay
          CustomPaint(
            painter: FaceOvalPainter(status: scannerState.status),
          ),

          // 3. UI Overlays (Back button, status, etc.)
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                
                // Status Text
                if (scannerState.message != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scannerState.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                
                const SizedBox(height: 40),

                // Progress Indicator during processing
                if (scannerState.status == ScannerStatus.processing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      strokeWidth: 6,
                    ),
                  ),

                // Success Card
                if (scannerState.status == ScannerStatus.success)
                  _buildResultCard(
                    title: 'Success!',
                    subtitle: '${scannerState.matchedName} - ${DateTime.now().hour}:${DateTime.now().minute}',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),

                // Failure Card
                if (scannerState.status == ScannerStatus.failure)
                  _buildResultCard(
                    title: 'Failed',
                    subtitle: _getErrorMessage(scannerState.error),
                    color: Colors.red,
                    icon: Icons.error,
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String? error) {
    if (error == null) return 'Try again';
    if (error.contains('Liveness')) {
      return 'Liveness failed. Please ensure you are a real person and try again.';
    }
    if (error.contains('brighter')) {
      return 'Too dark. Please move to a brighter area.';
    }
    if (error.contains('still')) {
      return 'Please hold still while scanning.';
    }
    if (error.contains('Multiple')) {
      return 'Multiple faces detected. Please scan one person at a time.';
    }
    if (error.contains('not found')) {
      return 'Face not recognized. Please ensure you are enrolled.';
    }
    return error;
  }

  Widget _buildResultCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Row(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
