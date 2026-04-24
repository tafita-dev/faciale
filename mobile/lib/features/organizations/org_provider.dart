import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class OrgState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  OrgState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  OrgState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return OrgState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final orgProvider = NotifierProvider<OrgNotifier, OrgState>(() {
  return OrgNotifier();
});

class OrgNotifier extends Notifier<OrgState> {
  final String _baseUrl = 'http://192.168.0.20:4000/api/v1';

  @override
  OrgState build() {
    return OrgState();
  }

  Future<void> createOrg(String name, String type) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.post(
        Uri.parse('$_baseUrl/orgs/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.token}',
        },
        body: jsonEncode({
          'name': name,
          'type': type,
        }),
      );

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to create organization',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  void reset() {
    state = OrgState();
  }
}
