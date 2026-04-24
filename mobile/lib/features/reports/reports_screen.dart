import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_provider.dart';

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

    // Listen for errors and show snackbar
    ref.listen(reportsProvider.select((s) => s.error), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (state.isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: () => ref.read(reportsProvider.notifier).exportLogs(),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.logs.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No attendance logs found.')),
        ],
      );
    }

    return ListView.builder(
      itemCount: state.logs.length,
      itemBuilder: (context, index) {
        final log = state.logs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(log.status).withOpacity(0.1),
            child: Icon(
              _getStatusIcon(log.status),
              color: _getStatusColor(log.status),
            ),
          ),
          title: Text(
            log.employeeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_formatTimestamp(log.timestamp)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(log.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              log.status,
              style: TextStyle(
                color: _getStatusColor(log.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
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
