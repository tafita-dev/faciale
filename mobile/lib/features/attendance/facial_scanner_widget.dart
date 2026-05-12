import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme.dart';
import '../employees/camera_provider.dart';
import 'face_detector_service.dart';
import 'face_painter.dart';
import 'scanner_state.dart';

class FacialScannerWidget extends ConsumerStatefulWidget {
  final Future<void> Function(String imagePath) onImageCaptured;
  final bool initialManualCapture;
  final bool showModeToggle;
  final Duration autoCaptureInterval;

  const FacialScannerWidget({
    super.key, 
    required this.onImageCaptured,
    this.initialManualCapture = false,
    this.showModeToggle = false,
    this.autoCaptureInterval = const Duration(seconds: 1),
  });

  @override
  ConsumerState<FacialScannerWidget> createState() => _FacialScannerWidgetState();
}

class _FacialScannerWidgetState extends ConsumerState<FacialScannerWidget> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isSwitching = false;
  Timer? _autoCaptureTimer;
  
  List<Face> _faces = [];
  bool _isFaceValid = false;
  bool _isFaceLive = false;
  bool _isProcessingFrame = false;
  late bool _isManualMode;

  @override
  void initState() {
    super.initState();
    _isManualMode = widget.initialManualCapture;
    _initializeCamera();
  }

  Future<void> _initializeCamera({CameraDescription? description}) async {
    try {
      final cameras = await ref.read(camerasProvider.future);
      if (cameras.isEmpty) return;

      final camera = description ?? cameras.first;
      
      _controller = CameraController(
        camera, 
        ResolutionPreset.high, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, 
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        _startImageStream();
        if (!_isManualMode) _startAutoCapture();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((image) async {
      if (_isProcessingFrame || _isSwitching) return;
      
      _isProcessingFrame = true;
      try {
        final faceDetector = ref.read(faceDetectorServiceProvider);
        
        final inputImage = _convertCameraImage(image);
        if (inputImage != null) {
          final faces = await faceDetector.detectFacesFromInputImage(inputImage);
          
          if (mounted) {
            setState(() {
              _faces = faces;
              if (faces.isNotEmpty) {
                _isFaceValid = faceDetector.isFaceValid(faces.first);
                _isFaceLive = faceDetector.isLive(faces.first);
              } else {
                _isFaceValid = false;
                _isFaceLive = false;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error processing stream frame: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _controller!.description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        (defaultTargetPlatform == TargetPlatform.android
            ? InputImageFormat.yuv420
            : InputImageFormat.bgra8888);

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void _startAutoCapture() {
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = Timer.periodic(widget.autoCaptureInterval, (timer) {
      if (_isInitialized && _controller != null && !_isManualMode && _isFaceValid && _isFaceLive && !_controller!.value.isTakingPicture) {
        _takePicture();
      }
    });
  }

  void _toggleCaptureMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      if (!_isManualMode) {
        _startAutoCapture();
      } else {
        _autoCaptureTimer?.cancel();
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_controller == null || _isSwitching) return;
    
    _autoCaptureTimer?.cancel();
    await _controller!.stopImageStream();
    setState(() => _isSwitching = true);

    try {
      final cameras = await ref.read(camerasProvider.future);
      if (cameras.length < 2) return;

      final lensDirection = _controller!.description.lensDirection;
      final newDescription = cameras.firstWhere(
        (c) => c.lensDirection != lensDirection,
        orElse: () => cameras.first,
      );

      await _controller!.dispose();
      await _initializeCamera(description: newDescription);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;
    
    try {
      final image = await _controller!.takePicture();
      await widget.onImageCaptured(image.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final size = _controller!.value.previewSize;
    final imageSize = Size(size?.height ?? 1, size?.width ?? 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        
        if (_faces.isNotEmpty)
          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              imageSize: imageSize,
              isFaceValid: _isFaceValid && _isFaceLive,
            ),
          ),

        if (_isSwitching)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        Positioned(
          top: 40,
          right: 20,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                onPressed: _switchCamera,
              ),
              if (widget.showModeToggle) ...[
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(
                    _isManualMode ? Icons.camera_alt : Icons.bolt, 
                    color: Colors.white, 
                    size: 30
                  ),
                  onPressed: _toggleCaptureMode,
                ),
              ],
            ],
          ),
        ),

        if (_isManualMode && _isFaceValid && _isFaceLive)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        if ((!_isFaceValid || !_isFaceLive) && _faces.isNotEmpty)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (!_isFaceValid ? 'center_your_face' : 'blink_your_eyes').tr().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
