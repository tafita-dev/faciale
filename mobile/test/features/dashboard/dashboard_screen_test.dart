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
}

void main() {
  testWidgets('Dashboard Screen shows Org Admin views by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify Org Admin specific cards
    expect(find.text('Present Today'), findsOneWidget);
    expect(find.text('Total Employees'), findsOneWidget);
    expect(find.text('Late/Absent'), findsOneWidget);

    // Verify Real-time Feed section
    expect(find.text('Recent Check-ins'), findsOneWidget);

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
    expect(find.text('Active Organizations'), findsOneWidget);
    expect(find.text('System Health'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);

    // Should NOT show Organization specific cards
    expect(find.text('Present Today'), findsNothing);
    
    // Verify FAB action for Super Admin
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add Organization'), findsOneWidget);
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

    // Manually navigate to /dashboard because initialLocation is /login
    // GoRouter in tests might need a pumpAndSettle after navigation
    final element = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(element);
    container.read(routerProvider).go('/dashboard');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Add Organization'));
    await tester.pumpAndSettle();

    expect(find.text('Create Organization'), findsOneWidget);
    expect(find.text('Organization Name'), findsOneWidget);
  });

  testWidgets('Dashboard Screen FAB opens options for Org Admin', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Quick Scan'), findsOneWidget);
    expect(find.text('Add Employee'), findsOneWidget);
  });
}
