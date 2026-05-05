import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';
import 'package:faciale/features/organizations/create_org_screen.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
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
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateOrgScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        authProvider.overrideWith(() => MockAuthNotifier(AuthState(token: 'test_token', role: 'superadmin'))),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders Create Organization form', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    GoRouter.of(tester.element(find.text('Dashboard'))).push('/create');
    await tester.pumpAndSettle();

    expect(find.text('organization_name'), findsOneWidget);
    expect(find.text('type'), findsOneWidget);
    expect(find.text('admin_full_name'), findsOneWidget);
    expect(find.text('admin_email'), findsOneWidget);
    expect(find.text('admin_password'), findsOneWidget);
    expect(find.byType(NeumorphicButton), findsOneWidget);
    expect(find.descendant(
      of: find.byType(NeumorphicButton),
      matching: find.text('CREATE_ORGANIZATION'),
    ), findsOneWidget);
    
    // Check for logo picker placeholder
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    expect(find.text('add_logo'), findsOneWidget);
  });

  testWidgets('shows validation error when name is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    GoRouter.of(tester.element(find.text('Dashboard'))).push('/create');
    await tester.pumpAndSettle();

    final button = find.byType(NeumorphicButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('org_name_required'), findsOneWidget);
  });

  testWidgets('creates organization successfully and shows success message', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    GoRouter.of(tester.element(find.text('Dashboard'))).push('/create');
    await tester.pumpAndSettle();

    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(
          jsonEncode({
            '_id': 'org123',
            'name': 'Test School',
            'type': 'school',
            'created_at': DateTime.now().toIso8601String(),
          }),
          201,
        ));

    // Fill the form
    await tester.enterText(find.widgetWithText(TextFormField, 'organization_name'), 'Test School');
    await tester.enterText(find.widgetWithText(TextFormField, 'admin_full_name'), 'Admin Name');
    await tester.enterText(find.widgetWithText(TextFormField, 'admin_email'), 'admin@test.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'admin_password'), 'password123');
    
    final button = find.byType(NeumorphicButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('organization_created_successfully'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
