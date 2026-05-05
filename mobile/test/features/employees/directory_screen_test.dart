import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/employees/directory_screen.dart';
import 'package:faciale/features/employees/employee_provider.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';

import 'directory_screen_test.mocks.dart';

@GenerateMocks([http.Client])
class MockAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      token: 'test_token',
      role: 'user',
    );
  }

  @override
  String get _baseUrl => '';

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> fetchProfile() async {}

  @override
  void resetStatus() {}
}

void main() {
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1\n');
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        authProvider.overrideWith(() => MockAuthNotifier()),
      ],
      child: const MaterialApp(
        home: DirectoryScreen(),
      ),
    );
  }

  final mockEmployees = [
    {'_id': '1', 'name': 'Alice', 'dept_id': 'd1'},
    {'_id': '2', 'name': 'Bob', 'dept_id': 'd2'},
  ];

  final mockDepts = [
    {'_id': 'd1', 'name': 'Engineering'},
    {'_id': 'd2', 'name': 'HR'},
  ];

  testWidgets('renders colleague list', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/directory?skip=0&limit=50'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Engineering'), findsNWidgets(2)); // Card + Filter chip
    expect(find.text('HR'), findsNWidgets(2)); // Card + Filter chip
  });
}
