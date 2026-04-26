import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';

class NavigationShell extends ConsumerWidget {
  const NavigationShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState.role == 'superadmin';

    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (!isSuperAdmin) ...[
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Employees',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined),
          activeIcon: Icon(Icons.assessment),
          label: 'Reports',
        ),
      ],
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(isSuperAdmin, navigationShell.currentIndex),
        onTap: (index) => _onTap(context, index, isSuperAdmin),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }

  int _calculateSelectedIndex(bool isSuperAdmin, int shellIndex) {
    if (!isSuperAdmin) return shellIndex;
    // For superadmin: 0 (Dashboard) -> 0, 3 (Profile) -> 1
    if (shellIndex == 0) return 0;
    if (shellIndex == 3) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index, bool isSuperAdmin) {
    int branchIndex = index;
    if (isSuperAdmin) {
      // index 0 -> Dashboard (branch 0)
      // index 1 -> Profile (branch 3)
      branchIndex = index == 0 ? 0 : 3;
    }

    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
