import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/organizations/org_list_screen.dart';
import 'package:faciale/features/organizations/org_provider.dart';
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

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
    mockClient = MockClient();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        authProvider.overrideWith(() => MockAuthNotifier(AuthState(token: 'test_token', role: 'superadmin'))),
      ],
      child: const MaterialApp(
        home: OrgListScreen(),
      ),
    );
  }

  testWidgets('renders list of organizations', (WidgetTester tester) async {
    final orgsJson = [
      {'_id': '1', 'name': 'Org 1', 'type': 'school', 'created_at': DateTime.now().toIso8601String()},
      {'_id': '2', 'name': 'Org 2', 'type': 'company', 'created_at': DateTime.now().toIso8601String()},
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Org 1'), findsOneWidget);
    expect(find.text('SCHOOL'), findsOneWidget);
    expect(find.text('Org 2'), findsOneWidget);
    expect(find.text('COMPANY'), findsOneWidget);
  });

  testWidgets('shows empty state when no organizations', (WidgetTester tester) async {
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No organizations found'), findsOneWidget);
  });

  testWidgets('shows delete confirmation dialog and deletes on confirm', (WidgetTester tester) async {
    final orgsJson = [
      {'_id': '1', 'name': 'Org 1', 'type': 'school', 'created_at': DateTime.now().toIso8601String()},
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Delete Organization'), findsOneWidget);
    expect(find.text('Are you sure you want to delete "Org 1"?'), findsOneWidget);

    when(mockClient.delete(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 204));
    
    // Refresh mock after delete
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Organization deleted successfully'), findsOneWidget);
    expect(find.text('No organizations found'), findsOneWidget);
  });
}
