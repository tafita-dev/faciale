class AuthState {
  final bool isLoading;
  final String? token;
  final String? role;
  final String? orgId;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? error;
  final bool isSuccess;

  AuthState({
    this.isLoading = false,
    this.token,
    this.role,
    this.orgId,
    this.email,
    this.name,
    this.photoUrl,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? role,
    String? orgId,
    String? email,
    String? name,
    String? photoUrl,
    String? error,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      role: role ?? this.role,
      orgId: orgId ?? this.orgId,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
