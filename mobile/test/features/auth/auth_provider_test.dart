import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'auth_provider_test.mocks.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockClient mockClient;
  late MockFlutterSecureStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
    mockClient = MockClient();
    mockStorage = MockFlutterSecureStorage();
    
    // Stub storage methods
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async => {});
    when(mockStorage.read(key: anyNamed('key')))
        .thenAnswer((_) async => null);
    when(mockStorage.delete(key: anyNamed('key')))
        .thenAnswer((_) async => {});

    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state is correct', () {
    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.token, null);
    expect(state.role, null);
  });

  test('login success updates state with token and role', () async {
    const dummyToken = "header.eyJzdWIiOiAidGVzdEB0ZXN0LmNvbSIsICJyb2xlIjogInN1cGVyYWRtaW4iLCAib3JnX2lkIjogIm9yZzEyMyJ9.signature";
    
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'access_token': dummyToken}),
              200,
            ));

    await container.read(authProvider.notifier).login('test@test.com', 'password');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.token, dummyToken);
    expect(state.role, 'superadmin');
    expect(state.error, null);
    
    verify(mockStorage.write(key: 'jwt_token', value: dummyToken)).called(1);
  });

  test('login failure updates state with error', () async {
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'detail': 'Invalid credentials'}),
              401,
            ));

    await container.read(authProvider.notifier).login('test@test.com', 'wrong');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.token, null);
    expect(state.role, null);
    expect(state.error, 'Invalid credentials');
  });

  test('login server error updates state with server error message', () async {
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              'Internal Server Error',
              500,
            ));

    await container.read(authProvider.notifier).login('test@test.com', 'password');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.error, 'Server error. Please try again later.');
  });

  test('login network error updates state with network error message', () async {
    when(mockClient.post(any, body: anyNamed('body')))
        .thenThrow(Exception('No internet'));

    await container.read(authProvider.notifier).login('test@test.com', 'password');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.error, 'Network error. Please check your connection.');
  });

  test('requestPasswordReset success', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'msg': 'success'}),
              200,
            ));

    await container.read(authProvider.notifier).requestPasswordReset('test@test.com');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.isSuccess, true);
    expect(state.error, null);
  });

  test('confirmPasswordReset success', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'msg': 'success'}),
              200,
            ));

    await container.read(authProvider.notifier).confirmPasswordReset('token', 'newpassword');

    final state = container.read(authProvider);
    expect(state.isLoading, false);
    expect(state.isSuccess, true);
    expect(state.error, null);
  });

  test('logout clears storage and resets state', () async {
    // Setup state via login
    const dummyToken = "header.eyJzdWIiOiAidGVzdEB0ZXN0LmNvbSIsICJyb2xlIjogInN1cGVyYWRtaW4iLCAib3JnX2lkIjogIm9yZzEyMyJ9.signature";
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'access_token': dummyToken}),
              200,
            ));
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(
              jsonEncode({'email': 'test@test.com', 'name': 'Test'}),
              200,
            ));

    await container.read(authProvider.notifier).login('test@test.com', 'password');
    expect(container.read(authProvider).token, dummyToken);

    await container.read(authProvider.notifier).logout();

    final state = container.read(authProvider);
    expect(state.token, null);
    expect(state.role, null);
    expect(state.name, null);

    verify(mockStorage.delete(key: 'jwt_token')).called(1);
    verify(mockStorage.delete(key: 'user_role')).called(1);
    verify(mockStorage.delete(key: 'org_id')).called(1);
  });
}
