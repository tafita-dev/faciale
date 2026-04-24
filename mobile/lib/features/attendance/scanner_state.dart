import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final String? error;

  ScannerState({
    this.status = ScannerStatus.idle,
    this.message,
    this.matchedName,
    this.error,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    String? message,
    String? matchedName,
    String? error,
  }) {
    return ScannerState(
      status: status ?? this.status,
      message: message ?? this.message,
      matchedName: matchedName ?? this.matchedName,
      error: error ?? this.error,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  Timer? _resetTimer;

  @override
  ScannerState build() {
    ref.onDispose(() => _resetTimer?.cancel());
    return ScannerState(status: ScannerStatus.scanning, message: 'Align your face');
  }

  void setStatus(ScannerStatus status, {String? message, String? name, String? error}) {
    _resetTimer?.cancel();
    state = state.copyWith(status: status, message: message, matchedName: name, error: error);

    // Auto reset after 2 seconds for success/failure
    if (status == ScannerStatus.success || status == ScannerStatus.failure) {
      _resetTimer = Timer(const Duration(seconds: 2), () {
        reset();
      });
    }
  }

  void reset() {
    _resetTimer?.cancel();
    state = ScannerState(status: ScannerStatus.scanning, message: 'Align your face');
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(() {
  return ScannerNotifier();
});
