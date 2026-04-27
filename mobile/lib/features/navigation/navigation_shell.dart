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
    final role = authState.role;
    final isSuperAdmin = role == 'superadmin';
    final isAdmin = role == 'admin';

    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Employees',
        )
      else if (!isSuperAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.contact_page_outlined),
          activeIcon: Icon(Icons.contact_page),
          label: 'Directory',
        ),
      if (!isSuperAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined),
          activeIcon: Icon(Icons.assessment),
          label: 'Reports',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(role, navigationShell.currentIndex),
        onTap: (index) => _onTap(context, index, role),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }

  int _calculateSelectedIndex(String? role, int shellIndex) {
    if (role == 'superadmin') {
      if (shellIndex == 0) return 0;
      if (shellIndex == 4) return 1;
      return 0;
    }
    if (role == 'admin') {
      // Branches: 0: Dashboard, 1: Employees, 2: Directory (skip), 3: Reports, 4: Profile
      if (shellIndex == 0) return 0;
      if (shellIndex == 1) return 1;
      if (shellIndex == 3) return 2;
      if (shellIndex == 4) return 3;
      return 0;
    }
    // role == 'user'
    // Branches: 0: Dashboard, 1: Employees (skip), 2: Directory, 3: Reports, 4: Profile
    if (shellIndex == 0) return 0;
    if (shellIndex == 2) return 1;
    if (shellIndex == 3) return 2;
    if (shellIndex == 4) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index, String? role) {
    int branchIndex = index;
    if (role == 'superadmin') {
      branchIndex = index == 0 ? 0 : 4;
    } else if (role == 'admin') {
      if (index == 0) branchIndex = 0;
      if (index == 1) branchIndex = 1;
      if (index == 2) branchIndex = 3;
      if (index == 3) branchIndex = 4;
    } else {
      // user
      if (index == 0) branchIndex = 0;
      if (index == 1) branchIndex = 2;
      if (index == 2) branchIndex = 3;
      if (index == 3) branchIndex = 4;
    }

    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
