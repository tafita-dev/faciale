import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/organizations/create_org_screen.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
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
}

void main() {
  late MockClient mockClient;

  setUp(() {
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

    expect(find.text('Organization Name'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('shows validation error when name is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    GoRouter.of(tester.element(find.text('Dashboard'))).push('/create');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(find.text('Organization name is required'), findsOneWidget);
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

    await tester.enterText(find.byType(TextField), 'Test School');
    
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Organization created successfully'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    
    verify(mockClient.post(
      Uri.parse('http://192.168.0.20:4000/api/v1/orgs/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test_token',
      },
      body: jsonEncode({
        'name': 'Test School',
        'type': 'school',
      }),
    )).called(1);
  });
}
