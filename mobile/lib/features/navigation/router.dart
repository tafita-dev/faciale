import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../dashboard/dashboard_screen.dart';
import '../employees/employees_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../attendance/scanner_screen.dart';
import '../auth/login_screen.dart';
import '../employees/enroll_screen.dart';
import '../organizations/create_org_screen.dart';
import 'navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/enroll',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnrollScreen(),
      ),
      GoRoute(
        path: '/admin/org/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateOrgScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employees',
                builder: (context, state) => const EmployeesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/scanner',
        parentNavigatorKey: _rootNavigatorKey, // Ensures it's full-screen
        builder: (context, state) => const ScannerScreen(),
      ),
    ],
  );
});
