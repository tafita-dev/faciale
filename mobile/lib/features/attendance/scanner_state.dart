import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/network/connectivity_provider.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'attendance_repository.dart';
import 'face_detector_service.dart';

final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService();
  ref.onDispose(() => service.dispose());
  return service;
});

enum ScannerStatus {
  idle,
  scanning, // Face not detected or misaligned
  processing, // Face detected and matching
  success,
  failure
}

enum ScanningMode {
  auto,
  entry,
  exit
}

class ScannerState {
  final ScannerStatus status;
  final ScanningMode scanningMode;
  final String? message;
  final String? matchedName;
  final String? checkInType;
  final double? score;
  final String? error;
  final String? uiColor;

  ScannerState({
    this.status = ScannerStatus.idle,
    this.scanningMode = ScanningMode.auto,
    this.message,
    this.matchedName,
    this.checkInType,
    this.score,
    this.error,
    this.uiColor,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    ScanningMode? scanningMode,
    String? message,
    String? matchedName,
    String? checkInType,
    double? score,
    String? error,
    String? uiColor,
  }) {
    return ScannerState(
      status: status ?? this.status,
      scanningMode: scanningMode ?? this.scanningMode,
      message: message ?? this.message,
      matchedName: matchedName ?? this.matchedName,
      checkInType: checkInType ?? this.checkInType,
      score: score ?? this.score,
      error: error ?? this.error,
      uiColor: uiColor ?? this.uiColor,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  Timer? _resetTimer;
  bool _isProcessing = false;

  @override
  ScannerState build() {
    ref.onDispose(() => _resetTimer?.cancel());
    return ScannerState(status: ScannerStatus.scanning, message: 'align_your_face'.tr());
  }

  void setScanningMode(ScanningMode mode) {
    state = state.copyWith(scanningMode: mode);
  }

  void setStatus(ScannerStatus status, {String? message, String? name, String? type, double? score, String? error, String? uiColor}) {
    _resetTimer?.cancel();
    state = state.copyWith(
      status: status, 
      message: message, 
      matchedName: name, 
      checkInType: type,
      score: score,
      error: error,
      uiColor: uiColor,
    );

    // Auto reset after 1 second for failure AND success
    if (status == ScannerStatus.failure || status == ScannerStatus.success) {
      _resetTimer = Timer(const Duration(seconds: 1), () {
        reset();
      });
    }
  }

  Future<void> processImage(String imagePath) async {
    if (state.status != ScannerStatus.scanning || _isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      // Local detection first
      final faceDetector = ref.read(faceDetectorServiceProvider);
      final faces = await faceDetector.detectFaces(imagePath);

      if (faces.isEmpty) {
        // No face detected, keep scanning
        _isProcessing = false;
        return;
      }

      // Local liveness check
      final face = faces.first;
      final isAlive = (face.leftEyeOpenProbability ?? 0) > 0.5 &&
                      (face.rightEyeOpenProbability ?? 0) > 0.5;

      // Local orientation check (centered within 15 degrees)
      final isCentered = (face.headEulerAngleX?.abs() ?? 0) < 15 &&
                         (face.headEulerAngleY?.abs() ?? 0) < 15;

      if (!isAlive) {
        setStatus(
          ScannerStatus.failure,
          message: 'liveness_failed'.tr(),
          uiColor: 'red',
        );
        _isProcessing = false;
        return;
      }

      if (!isCentered) {
        setStatus(
          ScannerStatus.scanning,
          message: 'center_your_face'.tr(),
        );
        _isProcessing = false;
        return;
      }

      // Face detected and alive, proceed to API
      setStatus(ScannerStatus.processing, message: 'analyzing'.tr());

      final repository = ref.read(attendanceRepositoryProvider);
      final connectivity = ref.read(connectivityProvider);
      final isOffline = connectivity.maybeWhen(
        data: (status) => status == ConnectivityStatus.isDisconnected,
        orElse: () => false,
      );
      
      String? forceType;
      if (state.scanningMode == ScanningMode.entry) forceType = 'entry';
      if (state.scanningMode == ScanningMode.exit) forceType = 'exit';

      final auth = ref.read(authProvider);
      final result = await repository.checkIn(
        imagePath, 
        forceType: forceType, 
        isOffline: isOffline,
        orgId: auth.orgId,
        userId: auth.userId,
      );

      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final ui = result['ui'] ?? {};
        setStatus(
          ScannerStatus.success, 
          message: result['message'],
          name: data['employee_name'],
          type: data['type'],
          score: data['score'] != null ? (data['score'] as num).toDouble() : null,
          uiColor: ui['color'],
        );
      } else {
        final ui = result['ui'] ?? {};
        setStatus(
          ScannerStatus.failure,
          message: 'failed'.tr(),
          error: result['message'],
          uiColor: ui['color'] ?? 'red',
        );
      }
    } catch (e) {
      setStatus(
        ScannerStatus.failure,
        message: 'error'.tr(),
        error: e.toString(),
        uiColor: 'red',
      );
    } finally {
      _isProcessing = false;
    }
  }

  void reset() {
    _isProcessing = false;
    _resetTimer?.cancel();
    state = ScannerState(status: ScannerStatus.scanning, message: 'align_your_face'.tr());
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(() {
  return ScannerNotifier();
});

