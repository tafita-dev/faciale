import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../auth/auth_provider.dart';
import 'employee_provider.dart';
import '../organizations/department_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/employee_tile.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String? _selectedDeptId;
  bool _groupByDept = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(employeeProvider.notifier).fetchEmployees();
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final employeeState = ref.watch(employeeProvider);
    final deptState = ref.watch(departmentProvider);
    final isAdmin = authState.role == 'admin';

    List<Employee> filteredEmployees = employeeState.employees;
    
    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filteredEmployees = filteredEmployees
          .where((emp) => emp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by Department
    if (_selectedDeptId != null) {
      filteredEmployees = filteredEmployees
          .where((emp) => emp.deptId == _selectedDeptId)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('employees'.tr()),
            Text(
              isAdmin ? 'organization_wide'.tr() : 'my_managed_employees'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_groupByDept ? Icons.group_work : Icons.group_work_outlined),
            onPressed: () => setState(() => _groupByDept = !_groupByDept),
            tooltip: 'toggle_grouping'.tr(),
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'filter_by_department'.tr(),
            onSelected: (deptId) => setState(() => _selectedDeptId = deptId),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text('all_departments'.tr()),
              ),
              ...deptState.departments.map((dept) => PopupMenuItem(
                    value: dept.id,
                    child: Text(dept.name),
                  )),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: NeumorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 30,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'search_by_name'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: employeeState.isLoading || deptState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (employeeState.error != null || deptState.error != null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        employeeState.error ?? deptState.error ?? 'unknown_error'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(employeeProvider.notifier).fetchEmployees();
                          ref.read(departmentProvider.notifier).fetchDepartments();
                        },
                        child: Text('retry'.tr()),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(employeeProvider.notifier).fetchEmployees();
                    await ref.read(departmentProvider.notifier).fetchDepartments();
                  },
                  child: filteredEmployees.isEmpty
                      ? Center(child: Text('no_employees_found'.tr()))
                      : _buildEmployeeList(filteredEmployees, deptState.departments),
                ),
    );
  }

  Widget _buildEmployeeList(List<Employee> employees, List<Department> depts) {
    if (!_groupByDept) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: employees.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEmployeeTile(employees[index], depts),
        ),
      );
    }

    // Grouping logic
    final Map<String, List<Employee>> grouped = {};
    for (var emp in employees) {
      grouped.putIfAbsent(emp.deptId, () => []).add(emp);
    }

    // Sort departments by name
    final sortedDeptIds = grouped.keys.toList()
      ..sort((a, b) {
        final nameA = depts.firstWhere((d) => d.id == a, orElse: () => Department(id: a, name: 'Unknown')).name;
        final nameB = depts.firstWhere((d) => d.id == b, orElse: () => Department(id: b, name: 'Unknown')).name;
        return nameA.compareTo(nameB);
      });

    // Flatten the list for better performance with ListView.builder
    final List<dynamic> flattenedItems = [];
    for (var deptId in sortedDeptIds) {
      final deptName = depts.firstWhere((d) => d.id == deptId, orElse: () => Department(id: deptId, name: 'Unknown')).name;
      flattenedItems.add(deptName); // Use String as header marker
      flattenedItems.addAll(grouped[deptId]!);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: flattenedItems.length,
      itemBuilder: (context, index) {
        final item = flattenedItems[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Text(
              item.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEmployeeTile(item as Employee, depts),
          );
        }
      },
    );
  }

  Widget _buildEmployeeTile(Employee employee, List<Department> depts) {
    final authState = ref.watch(authProvider);
    final deptName = depts.firstWhere((d) => d.id == employee.deptId, orElse: () => Department(id: employee.deptId, name: 'Unknown')).name;

    return EmployeeTile(
      employee: employee,
      departmentName: deptName,
      authToken: authState.token,
      trailing: employee.isEnrolled
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : const Icon(Icons.error_outline, color: AppColors.error),
    );
  }
}
