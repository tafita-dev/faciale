class AuthState {
  final bool isLoading;
  final String? token;
  final String? role;
  final String? error;
  final bool isSuccess;

  AuthState({
    this.isLoading = false,
    this.token,
    this.role,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? role,
    String? error,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      role: role ?? this.role,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
