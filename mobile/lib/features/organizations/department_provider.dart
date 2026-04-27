import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_provider.dart';

class DeptState {
  final bool isLoading;
  final String? error;
  final List<Department> departments;

  DeptState({
    this.isLoading = false,
    this.error,
    this.departments = const [],
  });

  DeptState copyWith({
    bool? isLoading,
    String? error,
    List<Department>? departments,
  }) {
    return DeptState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      departments: departments ?? this.departments,
    );
  }
}

class Department {
  final String id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] as String,
      name: json['name'] as String,
    );
  }
}

final departmentProvider = NotifierProvider<DepartmentNotifier, DeptState>(() {
  return DepartmentNotifier();
});

class DepartmentNotifier extends Notifier<DeptState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  DeptState build() {
    return DeptState();
  }

  Future<void> fetchDepartments() async {
    print('DEBUG: fetchDepartments called');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      print('DEBUG: fetchDepartments fetching from ${_baseUrl}/departments/');
      
      final response = await client.get(
        Uri.parse('$_baseUrl/departments/'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      print('DEBUG: fetchDepartments response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final depts = data.map((item) => Department.fromJson(item)).toList();
        state = state.copyWith(isLoading: false, departments: depts);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch departments',
        );
      }
    } catch (e, stack) {
      print('DEBUG: department_provider error: $e');
      print('DEBUG: department_provider stack: $stack');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<bool> createDepartment(String name) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final response = await client.post(
        Uri.parse('$_baseUrl/departments/'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        await fetchDepartments();
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to create department',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  Future<bool> updateDepartment(String id, String name) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final response = await client.put(
        Uri.parse('$_baseUrl/departments/$id'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        await fetchDepartments();
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to update department',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  Future<bool> deleteDepartment(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final response = await client.delete(
        Uri.parse('$_baseUrl/departments/$id'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 204) {
        state = state.copyWith(isLoading: false);
        await fetchDepartments();
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to delete department',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }
}
