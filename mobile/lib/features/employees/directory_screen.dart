import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../auth/auth_provider.dart';
import 'employee_provider.dart';
import '../organizations/department_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/employee_tile.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(directoryProvider.notifier).fetchDirectory();
      ref.read(departmentProvider.notifier).fetchDepartments();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(directoryProvider);
      if (!state.isLoading) {
        ref.read(directoryProvider.notifier).fetchDirectory(skip: state.employees.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final directoryState = ref.watch(directoryProvider);
    final deptState = ref.watch(departmentProvider);
    final authState = ref.watch(authProvider);

    List<Employee> filteredEmployees = directoryState.employees;

    if (_searchQuery.isNotEmpty) {
      filteredEmployees = filteredEmployees
          .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedDeptId != null) {
      filteredEmployees = filteredEmployees
          .where((e) => e.deptId == _selectedDeptId)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('colleagues_directory'.tr()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: NeumorphicCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: 30,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'search_colleagues'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4.0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('all'.tr()),
                      selected: _selectedDeptId == null,
                      onSelected: (_) => setState(() => _selectedDeptId = null),
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    ...deptState.departments.map((dept) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(dept.name),
                            selected: _selectedDeptId == dept.id,
                            onSelected: (_) => setState(() => _selectedDeptId = dept.id),
                            backgroundColor: AppColors.background,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: directoryState.isLoading && directoryState.employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(directoryProvider.notifier).fetchDirectory(),
              child: filteredEmployees.isEmpty
                  ? Center(child: Text('no_colleagues_found'.tr()))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredEmployees.length + (directoryState.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredEmployees.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final employee = filteredEmployees[index];
                        final deptName = deptState.departments
                            .firstWhere((d) => d.id == employee.deptId,
                                orElse: () => Department(id: '', name: 'Unknown'))
                            .name;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: EmployeeTile(
                            employee: employee,
                            departmentName: deptName,
                            authToken: authState.token,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
