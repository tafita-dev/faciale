import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

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
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
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
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> createOrg({
    required String name,
    required String type,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
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
          'admin_name': adminName,
          'admin_email': adminEmail,
          'admin_password': adminPassword,
        }),
      );

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        await fetchOrgs(); // Refresh list
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? data['msg'] ?? 'Failed to create organization',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> updateOrg(String id, {
    String? name,
    String? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.patch(
        Uri.parse('$_baseUrl/orgs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.token}',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (type != null) 'type': type,
        }),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        await fetchOrgs(); // Refresh list
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to update organization',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
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
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
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
        error: 'Network error. Please check your connection.',
      );
    }
  }

  void reset() {
    state = state.copyWith(isSuccess: false, isDeleteSuccess: false, error: null);
  }
}
