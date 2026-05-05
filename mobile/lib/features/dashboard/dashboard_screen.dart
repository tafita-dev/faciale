import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/logo.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';
import 'dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    
    // Listen for new notifications
    ref.listen(dashboardProvider.select((s) => s.lastNotification), (previous, next) {
      if (next != null) {
        _showNotification(context, next);
        ref.read(dashboardProvider.notifier).clearNotification();
      }
    });

    final authState = ref.watch(authProvider);
    final role = authState.role;
    final isSuperAdmin = role == 'superadmin';
    final isAdmin = role == 'admin';
    final isUser = role == 'user';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Logo(size: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
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
          padding: const EdgeInsets.all(24.0),
          children: [
            if (isSuperAdmin) ...[
              // Super Admin Summary Cards
              Row(
                children: [
                  _SummaryCard(
                    title: 'organizations'.tr(),
                    value: state.totalOrganizations.toString(),
                    color: AppColors.primary,
                    onTap: () => context.push('/admin/orgs'),
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    title: 'total_admins'.tr(),
                    value: state.totalAdmins.toString(),
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryCard(
                    title: 'total_users'.tr(),
                    value: state.totalUsers.toString(),
                    color: AppColors.text,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    title: 'total_employees'.tr(),
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
                    title: 'present_today'.tr(),
                    value: state.presentToday.toString(),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    title: isUser ? 'my_colleagues'.tr() : 'total_employees'.tr(),
                    value: state.totalEmployees.toString(),
                    color: AppColors.primary,
                    onTap: () => context.go(isUser ? '/directory' : '/employees'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryCard(
                    title: 'late_absent'.tr(),
                    value: state.lateAbsent.toString(),
                    color: AppColors.error,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 16),
                    _SummaryCard(
                      title: 'total_users'.tr(),
                      value: state.totalUsers.toString(),
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'recent_activity'.tr(),
                style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
              ),
              const SizedBox(height: 16),
              // Real-time Feed
              if (state.recentCheckIns.isEmpty)
                Center(child: Text('no_recent_activity'.tr()))
              else
                ...state.recentCheckIns.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          NeumorphicCard(
                            padding: const EdgeInsets.all(8),
                            borderRadius: 12,
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.employeeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${entry.timestamp} - ${_getLocalizedStatus(entry.type == 'exit' ? 'checked_out' : entry.status)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (entry.type != 'failure')
                            const Icon(Icons.check_circle, color: AppColors.success)
                          else
                            const Icon(Icons.error, color: AppColors.error),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.grey.shade400,
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.background,
          elevation: 0,
          onPressed: () {
            _showQuickActions(context, role);
          },
          child: const Icon(Icons.add, color: AppColors.primary),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, String? role) {
    final isSuperAdmin = role == 'superadmin';
    final isAdmin = role == 'admin';
    final isUser = role == 'user';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (isSuperAdmin)
                ListTile(
                  leading:
                      const Icon(Icons.business, color: AppColors.primary),
                  title: Text('add_organization'.tr()),
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
                    title: Text('quick_scan'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/scanner');
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.person_add, color: AppColors.primary),
                    title: Text('add_employee'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/enroll');
                    },
                  ),
                ],
                if (isAdmin) ...[
                  ListTile(
                    leading:
                        const Icon(Icons.person_add, color: AppColors.primary),
                    title: Text('create_user'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/user/create');
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.category, color: AppColors.primary),
                    title: Text('manage_departments'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/departments');
                    },
                  ),
                ],
              ],
              const SizedBox(height: 16),
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
    final card = NeumorphicCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
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

void _showNotification(BuildContext context, CheckInEntry log) {
  final isSuccess = log.type != 'failure';
  
  String message;
  if (isSuccess) {
    if (log.type == 'exit') {
      message = 'success_checkout_notif'.tr(args: [log.employeeName]);
    } else {
      message = 'success_checkin_notif'.tr(args: [log.employeeName, _getLocalizedStatus(log.status)]);
    }
  } else {
    final reason = log.reason?.toLowerCase() ?? 'unknown';
    message = 'error_checkin_notif'.tr(args: [_getLocalizedReason(reason)]);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

String _getLocalizedStatus(String status) {
  switch (status.toLowerCase()) {
    case 'present':
      return 'present'.tr();
    case 'late':
      return 'late'.tr();
    case 'absent':
      return 'absent'.tr();
    case 'checked_out':
      return 'checked_out'.tr();
    default:
      return status;
  }
}

String _getLocalizedReason(String reason) {
  switch (reason) {
    case 'spoof_detected':
      return 'spoof_detected_desc'.tr();
    case 'no_match':
      return 'no_match_desc'.tr();
    default:
      return 'unknown_error'.tr();
  }
}
