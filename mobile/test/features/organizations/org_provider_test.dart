import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/organizations/org_provider.dart';
import 'package:faciale/features/organizations/org_model.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_provider_test.mocks.dart';

class MockAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  final AuthState initialState;
  MockAuthNotifier(this.initialState);

  @override
  AuthState build() => initialState;
  
  @override
  Future<void> login(String email, String password) async {}
  
  @override
  Future<void> logout() async {}
}

void main() {
  late MockClient mockClient;
  late ProviderContainer container;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
    mockClient = MockClient();
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        authProvider.overrideWith(() => MockAuthNotifier(AuthState(token: 'test_token', role: 'superadmin'))),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('fetchOrgs success updates state with organizations', () async {
    final orgsJson = [
      {'_id': '1', 'name': 'Org 1', 'type': 'school', 'created_at': DateTime.now().toIso8601String()},
      {'_id': '2', 'name': 'Org 2', 'type': 'company', 'created_at': DateTime.now().toIso8601String()},
    ];

    when(mockClient.get(
      any,
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await container.read(orgProvider.notifier).fetchOrgs();

    final state = container.read(orgProvider);
    expect(state.isLoading, false);
    expect(state.orgs.length, 2);
    expect(state.orgs[0].name, 'Org 1');
    expect(state.orgs[1].name, 'Org 2');
    expect(state.error, null);
  });

  test('fetchOrgs failure updates state with error', () async {
    when(mockClient.get(
      any,
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response(jsonEncode({'detail': 'Error'}), 400));

    await container.read(orgProvider.notifier).fetchOrgs();

    final state = container.read(orgProvider);
    expect(state.isLoading, false);
    expect(state.orgs, isEmpty);
    expect(state.error, 'Error');
  });

  test('deleteOrganization success updates state and refreshes list', () async {
    when(mockClient.delete(
      any,
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response('', 204));

    // fetchOrgs mock for refresh
    when(mockClient.get(
      any,
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response('[]', 200));

    await container.read(orgProvider.notifier).deleteOrganization('1');

    final state = container.read(orgProvider);
    expect(state.isLoading, false);
    expect(state.isDeleteSuccess, true);
    expect(state.error, null);
    
    verify(mockClient.delete(any, headers: anyNamed('headers'))).called(1);
    verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
  });

  test('deleteOrganization failure updates state with error', () async {
    when(mockClient.delete(
      any,
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response(jsonEncode({'detail': 'Delete Error'}), 400));

    await container.read(orgProvider.notifier).deleteOrganization('1');

    final state = container.read(orgProvider);
    expect(state.isLoading, false);
    expect(state.isDeleteSuccess, false);
    expect(state.error, 'Delete Error');
  });
}
