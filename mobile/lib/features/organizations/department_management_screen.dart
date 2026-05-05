import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'department_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  ConsumerState<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends ConsumerState<DepartmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(departmentProvider.notifier).fetchDepartments());
  }

  void _showDepartmentDialog([Department? dept]) {
    final nameController = TextEditingController(text: dept?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(dept == null ? 'add_department'.tr() : 'edit_department'.tr()),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'department_name'.tr()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                if (dept == null) {
                  ref.read(departmentProvider.notifier).createDepartment(name);
                } else {
                  ref
                      .read(departmentProvider.notifier)
                      .updateDepartment(dept.id, name);
                }
                Navigator.pop(context);
              }
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
        title: Text('delete_department'.tr()),
        content: Text('delete_department_confirm'.tr(namedArgs: {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              ref.read(departmentProvider.notifier).deleteDepartment(id);
              Navigator.pop(context);
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
    final state = ref.watch(departmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('manage_departments'.tr())),
      body: state.isLoading && state.departments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(departmentProvider.notifier).fetchDepartments(),
              child: state.departments.isEmpty
                  ? Center(child: Text('no_departments_found'.tr()))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                        
                        if (crossAxisCount == 1) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: state.departments.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildDepartmentTile(state.departments[index]),
                              );
                            },
                          );
                        } else {
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 70,
                            ),
                            itemCount: state.departments.length,
                            itemBuilder: (context, index) => _buildDepartmentTile(state.departments[index]),
                          );
                        }
                      },
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
          onPressed: () => _showDepartmentDialog(),
          tooltip: 'add_department'.tr(),
          child: const Icon(Icons.add, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDepartmentTile(Department dept) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => _showDepartmentDialog(dept),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _showDeleteConfirmation(dept.id, dept.name),
            ),
          ],
        ),
      ),
    );
  }
}
