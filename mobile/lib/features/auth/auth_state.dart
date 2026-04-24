class AuthState {
  final bool isLoading;
  final String? token;
  final String? role;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.token,
    this.role,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? role,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      role: role ?? this.role,
      error: error ?? this.error,
    );
  }
}
