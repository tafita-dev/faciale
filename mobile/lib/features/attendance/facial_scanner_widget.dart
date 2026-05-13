import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../employees/camera_provider.dart';
import 'face_detector_service.dart';
import 'face_painter.dart';

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
  ConsumerState<FacialScannerWidget> createState() =>
      _FacialScannerWidgetState();
}

class _FacialScannerWidgetState extends ConsumerState<FacialScannerWidget> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isSwitching = false;
  bool _isProcessing = false;

  Timer? _timer;

  List<Face> _faces = [];
  bool _valid = false;
  bool _live = false;

  late bool _manual;

  @override
  void initState() {
    super.initState();
    _manual = widget.initialManualCapture;
    _initCamera();
  }

  // ================= CAMERA INIT =================
  Future<void> _initCamera({CameraDescription? cam}) async {
    final cameras = await ref.read(camerasProvider.future);
    if (cameras.isEmpty) return;

    final camera = cam ?? cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    await _controller!.setFocusMode(FocusMode.auto);
    await _controller!.setExposureMode(ExposureMode.auto);

    if (!mounted) return;

    setState(() => _isInitialized = true);

    _startStream();
    if (!_manual) _startAuto();
  }

  // ================= STREAM =================
  void _startStream() {
    _controller!.startImageStream((image) async {
      if (_isProcessing || _isSwitching) return;
      _isProcessing = true;

      try {
        final input = _convert(image);
        if (input == null) return;

        final detector = ref.read(faceDetectorServiceProvider);
        final faces = await detector.detectFacesFromInputImage(input);

        if (!mounted) return;

        setState(() {
          _faces = faces;

          if (faces.isNotEmpty) {
            _valid = detector.isFaceValid(faces.first);
            _live = detector.isLive(faces.first);
          } else {
            _valid = false;
            _live = false;
          }
        });
      } catch (_) {} finally {
        _isProcessing = false;
      }
    });
  }

  // ================= CONVERT =================
  InputImage? _convert(CameraImage image) {
    final camera = _controller!.description;

    final rotation = InputImageRotationValue.fromRawValue(
          camera.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    final format = defaultTargetPlatform == TargetPlatform.android
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final WriteBuffer buffer = WriteBuffer();
    for (final p in image.planes) {
      buffer.putUint8List(p.bytes);
    }

    final bytes = buffer.done().buffer.asUint8List();

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

  // ================= AUTO CAPTURE =================
  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoCaptureInterval, (_) {
      if (_valid && _live && _controller != null && !_manual) {
        _take();
      }
    });
  }

  // ================= SWITCH CAMERA (FIXED) =================
  Future<void> _switchCamera() async {
    if (_controller == null || _isSwitching) return;

    setState(() => _isSwitching = true);

    try {
      _timer?.cancel();
      await _controller!.stopImageStream();

      final cameras = await ref.read(camerasProvider.future);
      if (cameras.length < 2) return;

      final current = _controller!.description.lensDirection;

      final next = cameras.firstWhere(
        (c) => c.lensDirection != current,
        orElse: () => cameras.first,
      );

      await _controller!.dispose();

      await _initCamera(cam: next);
    } catch (e) {
      debugPrint("switch error $e");
    }

    setState(() => _isSwitching = false);
  }

  // ================= TAKE PHOTO =================
  Future<void> _take() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) return;

    final file = await _controller!.takePicture();
    await widget.onImageCaptured(file.path);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = _controller!.value.previewSize!;
    final imageSize = Size(size.height, size.width);

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),

        if (_faces.isNotEmpty)
          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              imageSize: imageSize,
              isFaceValid: _valid && _live,
            ),
          ),

        if (_isSwitching)
          const Center(child: CircularProgressIndicator()),

        Positioned(
          top: 40,
          right: 20,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.flip_camera_ios,
                    color: Colors.white, size: 30),
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),

        if (_manual && _valid && _live)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _take,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Center(
                    child: Icon(Icons.camera, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}