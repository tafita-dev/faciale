import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/auth/auth_provider.dart';
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
}
