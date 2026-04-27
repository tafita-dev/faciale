import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'department_provider.dart';
import '../../core/theme.dart';

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  ConsumerState<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends ConsumerState<DepartmentManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
  }

  void _showDepartmentDialog([Department? department]) {
    final isEditing = department != null;
    final nameController = TextEditingController(text: department?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Department' : 'Add Department'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Department Name',
            hintText: 'e.g. Engineering',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final notifier = ref.read(departmentProvider.notifier);
              final success = isEditing
                  ? await notifier.updateDepartment(department.id, name)
                  : await notifier.createDepartment(name);

              if (mounted && success) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete ${department.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(departmentProvider.notifier).deleteDepartment(department.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptState = ref.watch(departmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments'),
      ),
      body: deptState.isLoading && deptState.departments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (deptState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    color: AppColors.error.withOpacity(0.1),
                    child: Text(
                      deptState.error!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(departmentProvider.notifier).fetchDepartments(),
                    child: deptState.departments.isEmpty
                        ? const Center(child: Text('No departments found'))
                        : ListView.builder(
                            itemCount: deptState.departments.length,
                            itemBuilder: (context, index) {
                              final dept = deptState.departments[index];
                              return ListTile(
                                title: Text(dept.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary),
                                      onPressed: () => _showDepartmentDialog(dept),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.error),
                                      onPressed: () => _deleteDepartment(dept),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(),
        tooltip: 'Add Department',
        child: const Icon(Icons.add),
      ),
    );
  }
}
