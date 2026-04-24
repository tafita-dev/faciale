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
    final isSuperAdmin = authState.role == 'superadmin';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
                    title: 'Active Organizations',
                    value: state.totalOrganizations.toString(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'System Health',
                    value: state.systemHealth,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Total Users',
                value: state.totalUsers.toString(),
                color: AppColors.primary,
                isFullWidth: true,
              ),
            ] else ...[
              // Org Admin Summary Cards
              Row(
                children: [
                  _SummaryCard(
                    title: 'Present Today',
                    value: state.presentToday.toString(),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'Total Employees',
                    value: state.totalEmployees.toString(),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Late/Absent',
                value: state.lateAbsent.toString(),
                color: AppColors.error,
                isFullWidth: true,
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Check-ins',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Real-time Feed
              ...state.recentCheckIns.map((entry) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(entry.employeeName),
                  subtitle: Text(entry.timestamp),
                  trailing:
                      const Icon(Icons.check_circle, color: AppColors.success),
                );
              }),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          _showQuickActions(context, isSuperAdmin);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showQuickActions(BuildContext context, bool isSuperAdmin) {
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
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner,
                      color: AppColors.primary),
                  title: const Text('Quick Scan'),
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: card);
    } else {
      return Expanded(child: card);
    }
  }
}
