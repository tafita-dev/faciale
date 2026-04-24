import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faciale/main.dart';
import 'package:faciale/core/theme.dart';
import 'package:faciale/features/auth/login_screen.dart';
import 'package:camera/camera.dart';
import 'package:faciale/features/employees/camera_provider.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';

void main() {
  testWidgets('Global Theme and Navigation Presence Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          camerasProvider.overrideWith((ref) => Future.value([
            const CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 90,
            )
          ])),
        ],
        child: const FacialeApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Navigate to Dashboard
    final BuildContext context = tester.element(find.byType(LoginScreen));
    GoRouter.of(context).go('/dashboard');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Dashboard is the screen
    expect(find.text('Dashboard'), findsAtLeast(1));

    // Verify Theme: Primary color should be Deep Blue (#0047AB)
    final BuildContext dashboardContext = tester.element(find.text('Dashboard').first);
    final ThemeData theme = Theme.of(dashboardContext);
    expect(theme.colorScheme.primary, const Color(0xFF0047AB));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));

    // Verify Bottom Navigation Bar presence
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify Navigation Bar items
    expect(find.text('Dashboard'), findsAtLeast(1));
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Scanner screen hides navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          camerasProvider.overrideWith((ref) => Future.value([
            const CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 90,
            )
          ])),
        ],
        child: const FacialeApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Navigate to Dashboard
    final BuildContext context = tester.element(find.byType(LoginScreen));
    GoRouter.of(context).go('/dashboard');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Initial state: Dashboard with BottomNavigationBar
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Navigate to /scanner
    final BuildContext dashboardContext = tester.element(find.text('Dashboard').first);
    GoRouter.of(dashboardContext).go('/scanner');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify ScannerScreen is displayed
    expect(find.byType(ScannerScreen), findsOneWidget);
    expect(find.text('Align your face'), findsOneWidget);

    // Verify Bottom Navigation Bar is HIDDEN
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
