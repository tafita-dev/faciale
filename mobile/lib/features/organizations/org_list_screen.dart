import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'org_provider.dart';

class OrgListScreen extends ConsumerStatefulWidget {
  const OrgListScreen({super.key});

  @override
  ConsumerState<OrgListScreen> createState() => _OrgListScreenState();
}

class _OrgListScreenState extends ConsumerState<OrgListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orgProvider.notifier).fetchOrgs());
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(orgProvider.notifier).deleteOrganization(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orgProvider);

    ref.listen(orgProvider, (previous, next) {
      if (next.isDeleteSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(orgProvider.notifier).reset();
      } else if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Organizations')),
      body: state.isLoading && state.orgs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(orgProvider.notifier).fetchOrgs(),
              child: state.orgs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No organizations found'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(orgProvider.notifier).fetchOrgs(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.orgs.length,
                      itemBuilder: (context, index) {
                        final org = state.orgs[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child:
                                Icon(Icons.business, color: AppColors.primary),
                          ),
                          title: Text(org.name),
                          subtitle: Text(org.type.toUpperCase()),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () =>
                                _showDeleteConfirmation(org.id, org.name),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
