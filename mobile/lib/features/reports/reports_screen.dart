import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'reports_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reportsProvider.notifier).fetchLogs());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.role == 'admin';

    // Listen for errors and show snackbar
    ref.listen(reportsProvider.select((s) => s.error), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('reports'.tr()),
            Text(
              isAdmin ? 'organization_wide'.tr() : 'my_recordings_only'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (state.isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'export_csv'.tr(),
              onPressed: () => ref.read(reportsProvider.notifier).exportLogs(),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Analytics',
              onPressed: () => context.go('/reports/analytics'),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Implement filtering for admin (Date, Dept, User)
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reportsProvider.notifier).fetchLogs(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(state) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(reportsProvider.notifier).fetchLogs(),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state.logs.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text('no_attendance_logs'.tr())),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.logs.length,
      itemBuilder: (context, index) {
        final log = state.logs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NeumorphicCard(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: NeumorphicCard(
                padding: const EdgeInsets.all(8),
                borderRadius: 12,
                child: Icon(
                  _getStatusIcon(log.status),
                  color: _getStatusColor(log.status),
                ),
              ),
              title: Text(
                log.employeeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_formatTimestamp(log.timestamp), style: const TextStyle(fontSize: 12)),
              trailing: NeumorphicCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: 12,
                child: Text(
                  _getLocalizedStatus(log.status).toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(log.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
