import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_provider.dart';

class UserState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<OrgUser> users;

  UserState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.users = const [],
  });

  UserState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<OrgUser>? users,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
      users: users ?? this.users,
    );
  }
}

class OrgUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? orgId;

  OrgUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.orgId,
  });

  factory OrgUser.fromJson(Map<String, dynamic> json) {
    return OrgUser(
      id: json['_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      orgId: json['org_id'] as String?,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  UserState build() {
    return UserState();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.get(
        Uri.parse('$_baseUrl/users/'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data.map((item) => OrgUser.fromJson(item)).toList();
        state = state.copyWith(isLoading: false, users: users);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch users',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.post(
        Uri.parse('$_baseUrl/users/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.token}',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        await fetchUsers();
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to create user',
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
    state = state.copyWith(isSuccess: false, error: null);
  }
}
