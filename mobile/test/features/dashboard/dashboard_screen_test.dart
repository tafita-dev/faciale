import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/dashboard/dashboard_screen.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:faciale/features/navigation/router.dart';

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
  testWidgets('Dashboard Screen shows Org Admin views by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(AuthState(role: 'admin'))),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify Org Admin specific cards (expect translation keys when not initialized)
    expect(find.text('present_today'), findsOneWidget);
    expect(find.text('total_employees'), findsOneWidget);
    expect(find.text('late_absent'), findsOneWidget);

    // Verify Real-time Feed section
    expect(find.text('recent_activity'), findsOneWidget);

    // Verify FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Dashboard Screen shows Super Admin views when role is superadmin', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(AuthState(role: 'superadmin'))),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify Super Admin specific cards
    expect(find.text('organizations'), findsOneWidget);
    expect(find.text('total_admins'), findsOneWidget);
    expect(find.text('total_users'), findsOneWidget);

    // Should NOT show Organization specific cards
    expect(find.text('present_today'), findsNothing);
    
    // Verify FAB action for Super Admin
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('add_organization'), findsOneWidget);
  });

  testWidgets('Super Admin can navigate to Create Organization Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(AuthState(role: 'superadmin'))),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    final element = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(element);
    container.read(routerProvider).go('/dashboard');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('add_organization'));
    await tester.pumpAndSettle();

    // The header of the create org screen
    expect(find.text('create_organization'), findsAtLeast(1));
  });

  testWidgets('Dashboard Screen FAB opens options for Org Admin', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => MockAuthNotifier(AuthState(role: 'user'))),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('quick_scan'), findsOneWidget);
    expect(find.text('add_employee'), findsOneWidget);
  });
}
