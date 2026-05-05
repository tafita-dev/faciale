import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:developer' as developer;

abstract class NotificationDependencies {
  AuthState get authState;
  http.Client get httpClient;
}

class RiverpodNotificationDependencies implements NotificationDependencies {
  final Ref ref;
  RiverpodNotificationDependencies(this.ref);

  @override
  AuthState get authState => ref.read(authProvider);

  @override
  http.Client get httpClient => ref.read(httpClientProvider);
}

class NotificationService {
  final FirebaseMessaging messaging;
  final NotificationDependencies deps;

  NotificationService({
    required this.messaging,
    required this.deps,
  });

  Future<void> initialize() async {
    final auth = deps.authState;
    if (auth.token == null) return;

    try {
      await messaging.requestPermission();
      
      // Get the token
      final fcmToken = await messaging.getToken();
      
      if (fcmToken != null) {
        await _registerToken(fcmToken, auth.token!);
      }

      // Handle token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        final currentAuth = deps.authState;
        if (currentAuth.token != null) {
          _registerToken(newToken, currentAuth.token!);
        }
      });

    } catch (e) {
      developer.log('Error initializing notifications: $e');
    }
  }

  Future<void> _registerToken(String fcmToken, String jwt) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';
    final url = Uri.parse('$apiUrl/auth/fcm-token');

    try {
      final response = await deps.httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode != 200) {
        developer.log('Failed to register FCM token: ${response.body}');
      }
    } catch (e) {
      developer.log('Error registering FCM token: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: FirebaseMessaging.instance,
    deps: RiverpodNotificationDependencies(ref),
  );
});
