import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'org_model.dart';

class OrgState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<Org> orgs;
  final bool isDeleteSuccess;

  OrgState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.orgs = const [],
    this.isDeleteSuccess = false,
  });

  OrgState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<Org>? orgs,
    bool? isDeleteSuccess,
  }) {
    return OrgState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
      orgs: orgs ?? this.orgs,
      isDeleteSuccess: isDeleteSuccess ?? this.isDeleteSuccess,
    );
  }
}

final orgProvider = NotifierProvider<OrgNotifier, OrgState>(() {
  return OrgNotifier();
});

class OrgNotifier extends Notifier<OrgState> {
  String get _baseUrl => 'http://192.168.0.20:4000/api/v1';

  @override
  OrgState build() {
    return OrgState();
  }

  Future<void> fetchOrgs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.get(
        Uri.parse('$_baseUrl/orgs/'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final orgs = data.map((item) => Org.fromJson(item)).toList();
        state = state.copyWith(isLoading: false, orgs: orgs);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch organizations',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
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
        await fetchOrgs(); // Refresh list
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

  Future<void> deleteOrganization(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleteSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.delete(
        Uri.parse('$_baseUrl/orgs/$id'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 204) {
        state = state.copyWith(isLoading: false, isDeleteSuccess: true);
        await fetchOrgs(); // Refresh list
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to delete organization',
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
    state = state.copyWith(isSuccess: false, isDeleteSuccess: false, error: null);
  }
}
