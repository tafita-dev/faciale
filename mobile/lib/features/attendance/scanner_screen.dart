import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../employees/camera_provider.dart';
import 'scanner_state.dart';
import 'face_oval_painter.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  Timer? _scanTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Hide status bar and navigation bar for immersive view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _pulseController.dispose();
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
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 2), _scanningLoop);
  }

  Future<void> _scanningLoop() async {
    if (!mounted) return;
    
    // Only attempt capture if we are in scanning state
    final scannerState = ref.read(scannerProvider);
    if (scannerState.status == ScannerStatus.scanning) {
      await _attemptCapture();
    }
    
    // Schedule next scan if still mounted
    if (mounted) {
      _scanTimer = Timer(const Duration(seconds: 2), _scanningLoop);
    }
  }

  bool _isCapturing = false;

  Future<void> _attemptCapture() async {
    // 1. Guard against multiple simultaneous captures
    if (!mounted || _isCapturing) return;
    
    // 2. Camera readiness check
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      _isCapturing = true;
      final image = await _controller!.takePicture();
      
      // 3. Re-verify status before calling backend (status might have changed during takePicture)
      if (mounted && ref.read(scannerProvider).status == ScannerStatus.scanning) {
        await ref.read(scannerProvider.notifier).processImage(image.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    // Manage animation based on status
    if (scannerState.status == ScannerStatus.scanning) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      if (_pulseController.isAnimating) _pulseController.stop();
    }

    // Listen for success to show modal
    ref.listen(scannerProvider, (previous, next) {
      if (next.status == ScannerStatus.success && previous?.status != ScannerStatus.success) {
        SystemSound.play(SystemSoundType.click);
        _showSuccessModal(context, next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview - Only show if not processing/success/failure or as requested: 
          // "désactiver temporairement la caméra pendant le traitement backend"
          if (_isInitialized && _controller != null && scannerState.status == ScannerStatus.scanning)
            Center(
              child: CameraPreview(_controller!),
            )
          else if (scannerState.status == ScannerStatus.scanning)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            Container(color: Colors.black), // Black screen during processing/success

          // 2. Face Oval Overlay with Animation - Only during scanning
          if (scannerState.status == ScannerStatus.scanning)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FaceOvalPainter(
                    status: scannerState.status,
                    animationValue: _pulseController.value,
                  ),
                );
              },
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
                if (scannerState.message != null && scannerState.status == ScannerStatus.scanning)
                  NeumorphicCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    borderRadius: 30,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: Text(
                      scannerState.message!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),

                // Failure Card (Existing UI preserved as requested)
                if (scannerState.status == ScannerStatus.failure)
                  _buildResultCard(
                    title: 'failed'.tr(),
                    subtitle: _getErrorMessage(scannerState.error),
                    color: Colors.red,
                    icon: Icons.error,
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),

          // 4. Global Loading Overlay
          if (scannerState.status == ScannerStatus.processing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 6,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'analyzing'.tr().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessModal(BuildContext context, ScannerState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 24),
                Text(
                  'success'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.matchedName ?? 'Unknown',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.checkInType == "entry" ? "check_in".tr() : "check_out".tr()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (state.score != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${(state.score! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(scannerProvider.notifier).reset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String? error) {
    if (error == null) return 'try_again'.tr();
    if (error.contains('Liveness')) {
      return 'liveness_failed'.tr();
    }
    if (error.contains('brighter')) {
      return 'too_dark'.tr();
    }
    if (error.contains('still')) {
      return 'hold_still'.tr();
    }
    if (error.contains('Multiple')) {
      return 'multiple_faces'.tr();
    }
    if (error.contains('not found')) {
      return 'face_not_recognized'.tr();
    }
    return error;
  }

  Widget _buildResultCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return NeumorphicCard(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(), 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    subtitle, 
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
