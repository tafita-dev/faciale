import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:faciale/core/services/notification_service.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([FirebaseMessaging, http.Client, NotificationDependencies])
import 'notification_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
  });

  test('NotificationService does not register token if not logged in', () async {
    final mockFirebaseMessaging = MockFirebaseMessaging();
    final mockDeps = MockNotificationDependencies();
    
    when(mockDeps.authState).thenReturn(AuthState());

    final service = NotificationService(
      messaging: mockFirebaseMessaging,
      deps: mockDeps,
    );

    await service.initialize();

    verifyNever(mockFirebaseMessaging.getToken(vapidKey: anyNamed('vapidKey')));
  });

  test('NotificationService registers token when logged in', () async {
    final mockFirebaseMessaging = MockFirebaseMessaging();
    final mockClient = MockClient();
    final mockDeps = MockNotificationDependencies();

    when(mockDeps.authState).thenReturn(AuthState(token: 'user_jwt', email: 'test@test.com'));
    when(mockDeps.httpClient).thenReturn(mockClient);

    when(mockFirebaseMessaging.getToken(vapidKey: anyNamed('vapidKey'))).thenAnswer((_) async => 'fcm_token_123');
    when(mockFirebaseMessaging.requestPermission()).thenAnswer((_) async => const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    ));

    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(jsonEncode({'success': true}), 200));

    final service = NotificationService(
      messaging: mockFirebaseMessaging,
      deps: mockDeps,
    );

    await service.initialize();

    verify(mockFirebaseMessaging.getToken(vapidKey: anyNamed('vapidKey'))).called(1);
    verify(mockClient.post(
      argThat(predicate((Uri u) => u.path.endsWith('/auth/fcm-token'))),
      headers: argThat(containsPair('Authorization', 'Bearer user_jwt'), named: 'headers'),
      body: jsonEncode({'token': 'fcm_token_123'}),
    )).called(1);
  });
}
