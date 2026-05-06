import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'attendance_repository.dart';

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

    // Auto reset after 3 seconds for failure AND success
    if (status == ScannerStatus.failure || status == ScannerStatus.success) {
      _resetTimer = Timer(const Duration(seconds: 3), () {
        reset();
      });
    }
  }

  Future<void> processImage(String imagePath) async {
    // 1. Double-check status and local processing flag to prevent multiple calls
    if (state.status != ScannerStatus.scanning || _isProcessing) {
      debugPrint('ProcessImage ignored: status=${state.status}, isProcessing=$_isProcessing');
      return;
    }

    _isProcessing = true;
    
    // 2. Immediately set status to processing to block UI-side calls
    setStatus(ScannerStatus.processing, message: 'analyzing'.tr());

    try {
      final repository = ref.read(attendanceRepositoryProvider);
      
      String? forceType;
      if (state.scanningMode == ScanningMode.entry) forceType = 'entry';
      if (state.scanningMode == ScanningMode.exit) forceType = 'exit';

      final result = await repository.checkIn(imagePath, forceType: forceType);

      if (result['success'] == true) {
        final data = result['data'];
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
