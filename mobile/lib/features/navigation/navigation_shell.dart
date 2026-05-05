import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: const Icon(Icons.dashboard),
        label: 'dashboard'.tr(),
      ),
      if (isAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
          activeIcon: const Icon(Icons.people),
          label: 'employees'.tr(),
        )
      else if (!isSuperAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.contact_page_outlined),
          activeIcon: const Icon(Icons.contact_page),
          label: 'directory'.tr(),
        ),
      if (!isSuperAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.assessment_outlined),
          activeIcon: const Icon(Icons.assessment),
          label: 'reports'.tr(),
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: 'profile'.tr(),
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
