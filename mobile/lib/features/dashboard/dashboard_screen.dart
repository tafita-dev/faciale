import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final role = authState.role;
    final isSuperAdmin = role == 'superadmin';
    final isAdmin = role == 'admin';
    final isUser = role == 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (isSuperAdmin) ...[
              // Super Admin Summary Cards
              Row(
                children: [
                  _SummaryCard(
                    title: 'Organizations',
                    value: state.totalOrganizations.toString(),
                    color: AppColors.primary,
                    onTap: () => context.push('/admin/orgs'),
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'Total Admins',
                    value: state.totalAdmins.toString(),
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SummaryCard(
                    title: 'Total Users',
                    value: state.totalUsers.toString(),
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'Total Employees',
                    value: state.totalEmployees.toString(),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ] else ...[
              // Org Admin / User Summary Cards
              Row(
                children: [
                  _SummaryCard(
                    title: 'Present Today',
                    value: state.presentToday.toString(),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: isUser ? 'My Employees' : 'Total Employees',
                    value: state.totalEmployees.toString(),
                    color: AppColors.primary,
                    onTap: () => context.go('/employees'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SummaryCard(
                    title: 'Late/Absent',
                    value: state.lateAbsent.toString(),
                    color: AppColors.error,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    _SummaryCard(
                      title: 'Total Users',
                      value: state.totalUsers.toString(),
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isUser ? 'My Recent Recordings' : 'Recent Check-ins (All)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Real-time Feed
              if (state.recentCheckIns.isEmpty)
                const Center(child: Text('No recent activity'))
              else
                ...state.recentCheckIns.map((entry) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(entry.employeeName),
                    subtitle: Text('${entry.timestamp} - ${entry.status}'),
                    trailing: entry.status == 'success'
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : const Icon(Icons.error, color: AppColors.error),
                  );
                }),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          _showQuickActions(context, role);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showQuickActions(BuildContext context, String? role) {
    final isSuperAdmin = role == 'superadmin';
    final isAdmin = role == 'admin';
    final isUser = role == 'user';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSuperAdmin)
                ListTile(
                  leading:
                      const Icon(Icons.business, color: AppColors.primary),
                  title: const Text('Add Organization'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/org/create');
                  },
                )
              else ...[
                if (isUser) ...[
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner,
                        color: AppColors.primary),
                    title: const Text('Quick Scan (Pointage)'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/scanner');
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.person_add, color: AppColors.primary),
                    title: const Text('Add Employee'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/enroll');
                    },
                  ),
                ],
                if (isAdmin)
                  ListTile(
                    leading:
                        const Icon(Icons.person_add, color: AppColors.primary),
                    title: const Text('Create User'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/user/create');
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isFullWidth;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    this.isFullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: card);
    } else {
      return Expanded(child: card);
    }
  }
}
