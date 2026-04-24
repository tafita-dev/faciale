import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'auth_provider_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockClient();
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
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
    // This is a dummy JWT payload: {"sub": "test@test.com", "role": "superadmin", "org_id": "org123"}
    // Header: {"alg": "HS256", "typ": "JWT"}
    // Base64 encoded payload: eyJzdWIiOiAidGVzdEB0ZXN0LmNvbSIsICJyb2xlIjogInN1cGVyYWRtaW4iLCAib3JnX2lkIjogIm9yZzEyMyJ9
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
