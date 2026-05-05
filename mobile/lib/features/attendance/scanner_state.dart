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

class ScannerState {
  final ScannerStatus status;
  final String? message;
  final String? matchedName;
  final String? checkInType;
  final double? score;
  final String? error;

  ScannerState({
    this.status = ScannerStatus.idle,
    this.message,
    this.matchedName,
    this.checkInType,
    this.score,
    this.error,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    String? message,
    String? matchedName,
    String? checkInType,
    double? score,
    String? error,
  }) {
    return ScannerState(
      status: status ?? this.status,
      message: message ?? this.message,
      matchedName: matchedName ?? this.matchedName,
      checkInType: checkInType ?? this.checkInType,
      score: score ?? this.score,
      error: error ?? this.error,
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

  void setStatus(ScannerStatus status, {String? message, String? name, String? type, double? score, String? error}) {
    _resetTimer?.cancel();
    state = state.copyWith(
      status: status, 
      message: message, 
      matchedName: name, 
      checkInType: type,
      score: score,
      error: error
    );

    // Auto reset after 3 seconds ONLY for failure
    // Success requires manual acknowledgement via OK button
    if (status == ScannerStatus.failure) {
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
      final result = await repository.checkIn(imagePath);

      if (result['success'] == true) {
        final data = result['data'];
        setStatus(
          ScannerStatus.success, 
          message: result['message'],
          name: data['employee_name'],
          type: data['type'],
          score: data['score'] != null ? (data['score'] as num).toDouble() : null,
        );
      } else {
        setStatus(
          ScannerStatus.failure,
          message: 'failed'.tr(),
          error: result['message']
        );
      }
    } catch (e) {
      setStatus(
        ScannerStatus.failure,
        message: 'error'.tr(),
        error: e.toString()
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
