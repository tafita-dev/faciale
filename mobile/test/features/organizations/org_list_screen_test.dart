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
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> fetchProfile() async {}

  @override
  void resetStatus() {}
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
      {
        '_id': '1', 
        'name': 'Org 1', 
        'type': 'school', 
        'admin_email': 'admin1@test.com',
        'created_at': DateTime.now().toIso8601String()
      },
      {
        '_id': '2', 
        'name': 'Org 2', 
        'type': 'company', 
        'admin_email': 'admin2@test.com',
        'created_at': DateTime.now().toIso8601String()
      },
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Org 1'), findsOneWidget);
    expect(find.text('admin1@test.com'), findsOneWidget);
    expect(find.text('Org 2'), findsOneWidget);
    expect(find.text('admin2@test.com'), findsOneWidget);
  });

  testWidgets('shows empty state when no organizations', (WidgetTester tester) async {
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('no_organizations_found'), findsOneWidget);
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

    expect(find.text('delete_organization'), findsOneWidget);
    expect(find.text('delete_organization_confirm'), findsOneWidget);

    when(mockClient.delete(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 204));
    
    // Refresh mock after delete
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    expect(find.text('organization_deleted_successfully'), findsOneWidget);
    expect(find.text('no_organizations_found'), findsOneWidget);
  });

  testWidgets('shows edit dialog and updates on save', (WidgetTester tester) async {
    final orgsJson = [
      {'_id': '1', 'name': 'Org 1', 'type': 'school', 'created_at': DateTime.now().toIso8601String()},
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('edit_organization'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'organization_name'), findsOneWidget);

    // Enter new name
    await tester.enterText(find.widgetWithText(TextField, 'organization_name'), 'Org 1 Updated');
    
    // Select Company type
    await tester.tap(find.text('school'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('company').last);
    await tester.pumpAndSettle();

    when(mockClient.patch(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(jsonEncode({
          '_id': '1',
          'name': 'Org 1 Updated',
          'type': 'company',
          'created_at': DateTime.now().toIso8601String(),
        }), 200));

    // Refresh mock after update
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode([
          {
            '_id': '1', 
            'name': 'Org 1 Updated', 
            'type': 'company', 
            'admin_email': 'admin@test.com',
            'created_at': DateTime.now().toIso8601String()
          },
        ]), 200));

    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(find.text('organization_updated_successfully'), findsOneWidget);
    expect(find.text('Org 1 Updated'), findsOneWidget);
    expect(find.text('admin@test.com'), findsOneWidget);
  });

  testWidgets('displays organization logo when available', (WidgetTester tester) async {
    final orgsJson = [
      {
        '_id': '1',
        'name': 'Org with Logo',
        'type': 'school',
        'logo_url': 'http://example.com/logo.png',
        'created_at': DateTime.now().toIso8601String()
      },
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('displays default icon when logo is not available', (WidgetTester tester) async {
    final orgsJson = [
      {
        '_id': '1',
        'name': 'Org without Logo',
        'type': 'school',
        'logo_url': null,
        'created_at': DateTime.now().toIso8601String()
      },
    ];

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(orgsJson), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.business), findsOneWidget);
  });
}
