import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'auth_state.dart';

final httpClientProvider = Provider((ref) => http.Client());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final storage = ref.read(secureStorageProvider);
      
      final response = await client.post(
        Uri.parse('$_baseUrl/auth/login'),
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final role = decodedToken['role'];
        final orgId = decodedToken['org_id'];

        await storage.write(key: 'jwt_token', value: token);
        if (role != null) await storage.write(key: 'user_role', value: role);
        if (orgId != null) await storage.write(key: 'org_id', value: orgId);

        state = state.copyWith(
          token: token, 
          role: role, 
          orgId: orgId,
        );

        // Fetch full profile details
        await fetchProfile();
        
        state = state.copyWith(
          isLoading: false,
          isSuccess: true
        );
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> fetchProfile() async {
    final token = state.token;
    if (token == null) return;

    try {
      final client = ref.read(httpClientProvider);
      final response = await client.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          userId: data['id'],
          email: data['email'],
          name: data['name'],
          role: data['role'],
          photoUrl: data['photo_url'],
          orgId: data['org_id'],
        );
      }
    } catch (e) {
      // Fail silently for background profile fetch
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final response = await client.post(
        Uri.parse('$_baseUrl/auth/password-reset-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to complete request',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final response = await client.post(
        Uri.parse('$_baseUrl/auth/password-reset-confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else if (response.statusCode >= 500) {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error. Please try again later.',
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
      );
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'org_id');
    state = AuthState();
  }

  void resetStatus() {
    state = state.copyWith(error: null, isSuccess: false);
  }
}
