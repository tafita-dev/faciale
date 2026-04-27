import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'employee_provider.dart';
import '../organizations/department_provider.dart';
import '../../core/theme.dart';

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
      appBar: AppBar(
        title: const Text('Colleagues Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search colleagues...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedDeptId == null,
                      onSelected: (_) => setState(() => _selectedDeptId = null),
                    ),
                    const SizedBox(width: 8),
                    ...deptState.departments.map((dept) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(dept.name),
                            selected: _selectedDeptId == dept.id,
                            onSelected: (_) => setState(() => _selectedDeptId = dept.id),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: directoryState.isLoading && directoryState.employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(directoryProvider.notifier).fetchDirectory(),
              child: filteredEmployees.isEmpty
                  ? const Center(child: Text('No colleagues found'))
                  : ListView.builder(
                      controller: _scrollController,
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

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accent,
                              child: Text(
                                employee.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(employee.name),
                            subtitle: Text(deptName),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
