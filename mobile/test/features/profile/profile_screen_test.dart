import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faciale/features/profile/profile_screen.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
  });

  testWidgets('ProfileScreen displays full user data', (WidgetTester tester) async {
    final authState = AuthState(
      name: 'John Doe',
      email: 'john@example.com',
      role: 'admin',
      photoUrl: 'https://example.com/photo.jpg',
      token: 'test_token',
    );

    final mockAuthNotifier = AuthNotifierMock(authState);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    // Verify Name and Email are displayed
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);

    // Verify CachedNetworkImage is used
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    
    // Verify fetchProfile was called
    expect(mockAuthNotifier.fetchProfileCalled, isTrue);
  });

  testWidgets('ProfileScreen displays placeholder when no photoUrl', (WidgetTester tester) async {
    final authState = AuthState(
      name: 'Jane Doe',
      email: 'jane@example.com',
      role: 'user',
      photoUrl: null,
      token: 'test_token',
    );

    final mockAuthNotifier = AuthNotifierMock(authState);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    // Verify Name and Email
    expect(find.text('Jane Doe'), findsOneWidget);
    
    // Verify placeholder icon
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('ProfileScreen logout button triggers logout and redirect', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authState = AuthState(
      name: 'John Doe',
      email: 'john@example.com',
      role: 'admin',
      token: 'test_token',
    );

    final mockAuthNotifier = AuthNotifierMock(authState);

    // Mock router
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Find logout button in profile list
    final logoutButton = find.text('logout');
    await tester.ensureVisible(logoutButton);
    expect(logoutButton, findsOneWidget);

    // Tap logout to show dialog
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Find logout button in dialog
    final confirmLogoutButton = find.descendant(
      of: find.byType(TextButton),
      matching: find.text('logout'),
    );
    expect(confirmLogoutButton, findsOneWidget);

    // Tap confirm logout
    await tester.tap(confirmLogoutButton);
    await tester.pumpAndSettle();

    // Verify logout called
    expect(mockAuthNotifier.logoutCalled, isTrue);
    
    // Verify redirect to login
    expect(find.text('Login Screen'), findsOneWidget);
  });
}

class AuthNotifierMock extends Notifier<AuthState> implements AuthNotifier {
  final AuthState initialState;
  bool fetchProfileCalled = false;
  bool logoutCalled = false;

  AuthNotifierMock(this.initialState);

  @override
  AuthState build() => initialState;

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> fetchProfile() async {
    fetchProfileCalled = true;
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {}

  @override
  void resetStatus() {}
}
