import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'auth_state.dart';

final httpClientProvider = Provider((ref) => http.Client());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = 'http://192.168.0.20:4000/api/v1';

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final response = await client.post(
        Uri.parse('$_baseUrl/auth/login'),
        body: {
          'username': email,
          'password': password,
        },
      );
      print('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        // Decode JWT to get role
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final role = decodedToken['role'];
        final orgId = decodedToken['org_id'];

        await _storage.write(key: 'jwt_token', value: token);
        if (role != null) await _storage.write(key: 'user_role', value: role);
        if (orgId != null) await _storage.write(key: 'org_id', value: orgId);

        state = state.copyWith(isLoading: false, token: token, role: role);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      print( e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'org_id');
    state = AuthState();
  }
}
