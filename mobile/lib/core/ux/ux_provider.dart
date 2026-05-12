import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UXMessageType { success, error, info }

class UXMessage {
  final String text;
  final List<String>? args;
  final UXMessageType type;
  final DateTime timestamp;

  UXMessage({
    required this.text,
    this.args,
    this.type = UXMessageType.info,
  }) : timestamp = DateTime.now();
}

class UXState {
  final bool isLoading;
  final String? loadingMessage;
  final UXMessage? message;

  UXState({
    this.isLoading = false,
    this.loadingMessage,
    this.message,
  });

  UXState copyWith({
    bool? isLoading,
    String? loadingMessage,
    UXMessage? message,
    bool clearMessage = false,
  }) {
    return UXState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class UXNotifier extends Notifier<UXState> {
  @override
  UXState build() {
    return UXState();
  }

  void showLoading([String? message]) {
    state = state.copyWith(isLoading: true, loadingMessage: message);
  }

  void hideLoading() {
    state = state.copyWith(isLoading: false, loadingMessage: null);
  }

  void showSuccess(String text, {List<String>? args}) {
    state = state.copyWith(
      message: UXMessage(text: text, args: args, type: UXMessageType.success),
    );
  }

  void showError(String text, {List<String>? args}) {
    state = state.copyWith(
      message: UXMessage(text: text, args: args, type: UXMessageType.error),
    );
  }

  void showInfo(String text, {List<String>? args}) {
    state = state.copyWith(
      message: UXMessage(text: text, args: args, type: UXMessageType.info),
    );
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final uxProvider = NotifierProvider<UXNotifier, UXState>(() {
  return UXNotifier();
});
