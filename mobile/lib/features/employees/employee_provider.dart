import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_provider.dart';
import 'package:http_parser/http_parser.dart'; // Ajoute ceci

class EmployeeState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<Employee> employees;

  EmployeeState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.employees = const [],
  });

  EmployeeState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<Employee>? employees,
  }) {
    return EmployeeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
      employees: employees ?? this.employees,
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String deptId;
  final bool isEnrolled;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.name,
    required this.deptId,
    required this.isEnrolled,
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as String,
      name: json['name'] as String,
      deptId: json['dept_id'] as String,
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

final employeeProvider = NotifierProvider<EmployeeNotifier, EmployeeState>(() {
  return EmployeeNotifier();
});

final directoryProvider = NotifierProvider<DirectoryNotifier, EmployeeState>(() {
  return DirectoryNotifier();
});

class DirectoryNotifier extends Notifier<EmployeeState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  EmployeeState build() {
    return EmployeeState();
  }

  Future<void> fetchDirectory({int skip = 0, int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final response = await client.get(
        Uri.parse('$_baseUrl/employees/directory?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final employees = data.map((item) => Employee.fromJson(item)).toList();
        state = state.copyWith(
          isLoading: false,
          employees: skip == 0 ? employees : [...state.employees, ...employees],
        );
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch directory',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }
}

class EmployeeNotifier extends Notifier<EmployeeState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  EmployeeState build() {
    return EmployeeState();
  }

  Future<void> fetchEmployees() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      final response = await client.get(
        Uri.parse('$_baseUrl/employees/'),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final employees = data.map((item) => Employee.fromJson(item)).toList();
        state = state.copyWith(isLoading: false, employees: employees);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch employees',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> createAndEnrollEmployee({
    required String name,
    required String deptId,
    required String imagePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);
      
      // 1. Create Employee
      final createResponse = await client.post(
        Uri.parse('$_baseUrl/employees/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.token}',
        },
        body: jsonEncode({
          'name': name,
          'dept_id': deptId,
        }),
      );

      if (createResponse.statusCode == 201) {
        final employeeData = jsonDecode(createResponse.body);
        final employeeId = employeeData['_id'];

        // 2. Enroll (Upload Photo)
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/employees/$employeeId/enroll'),
        );
        request.headers['Authorization'] = 'Bearer ${authState.token}';
      final extension = imagePath.split('.').last.toLowerCase();
final type = (extension == 'png') ? 'png' : 'jpeg';

request.files.add(
  await http.MultipartFile.fromPath(
    'file', 
    imagePath,
    contentType: MediaType('image', type),
  ),

);

        final enrollResponse = await request.send();

        if (enrollResponse.statusCode == 202) {
          state = state.copyWith(isLoading: false, isSuccess: true);
          await fetchEmployees();
        } else {
          final responseData = await enrollResponse.stream.bytesToString();
          final data = jsonDecode(responseData);
          state = state.copyWith(
            isLoading: false,
            error: data['detail'] ?? 'Failed to enroll employee',
          );
        }
      } else {
        final data = jsonDecode(createResponse.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to create employee',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  void reset() {
    state = state.copyWith(isSuccess: false, error: null);
  }
}
