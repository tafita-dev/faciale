import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
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

  void _showEditDialog(String id, String currentName, String currentType) {
    final nameController = TextEditingController(text: currentName);
    String selectedType = currentType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('edit_organization'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'organization_name'.tr()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                DropdownMenuItem(value: 'school', child: Text('school'.tr())),
                DropdownMenuItem(value: 'company', child: Text('company'.tr())),
              ],
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(orgProvider.notifier).updateOrg(id,
                  name: nameController.text, type: selectedType);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('delete_organization'.tr()),
        content: Text('delete_organization_confirm'.tr(namedArgs: {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(orgProvider.notifier).deleteOrganization(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('delete'.tr()),
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
          SnackBar(
            content: Text('organization_deleted_successfully'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(orgProvider.notifier).reset();
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('organization_updated_successfully'.tr()),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('organizations'.tr())),
      body: state.isLoading && state.orgs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(orgProvider.notifier).fetchOrgs(),
              child: state.orgs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('no_organizations_found'.tr()),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(orgProvider.notifier).fetchOrgs(),
                            child: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: state.orgs.length,
                      itemBuilder: (context, index) {
                        final org = state.orgs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: NeumorphicCard(
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: NeumorphicCard(
                                padding: const EdgeInsets.all(8),
                                borderRadius: 12,
                                child:
                                    const Icon(Icons.business, color: AppColors.primary),
                              ),
                              title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(org.type.toUpperCase(), style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: AppColors.primary),
                                    onPressed: () => _showEditDialog(
                                        org.id, org.name, org.type),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: AppColors.error),
                                    onPressed: () =>
                                        _showDeleteConfirmation(org.id, org.name),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
