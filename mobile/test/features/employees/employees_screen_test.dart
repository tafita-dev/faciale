import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/employees/employees_screen.dart';
import 'package:faciale/features/employees/employee_provider.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:faciale/core/theme.dart';

import 'employees_screen_test.mocks.dart';

@GenerateMocks([http.Client])
class MockAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      token: 'test_token',
      role: 'admin',
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

  setUp(() async {
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
        home: EmployeesScreen(),
      ),
    );
  }

  final mockEmployees = [
    {'_id': '1', 'name': 'John Doe', 'dept_id': 'd1', 'is_enrolled': true},
    {'_id': '2', 'name': 'Jane Smith', 'dept_id': 'd1', 'is_enrolled': true},
    {'_id': '3', 'name': 'Bob Wilson', 'dept_id': 'd2', 'is_enrolled': false},
  ];

  final mockDepts = [
    {'_id': 'd1', 'name': 'Engineering'},
    {'_id': 'd2', 'name': 'HR'},
  ];

  testWidgets('shows loading state initially', (WidgetTester tester) async {
    final completer = Completer<http.Response>();
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Start the fetch

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    completer.complete(http.Response('[]', 200));
    await tester.pumpAndSettle();
  });

  testWidgets('renders list of employees', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger initState
    await tester.pump(); // Trigger microtask
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Bob Wilson'), findsOneWidget);
  });

  testWidgets('filters employees by department', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger initState
    await tester.pump(); // Trigger microtask
    await tester.pumpAndSettle();

    // Open filter
    await tester.tap(find.byTooltip('filter_by_department'));
    await tester.pumpAndSettle();

    // Select Engineering from popup menu
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Bob Wilson'), findsNothing);
  });

  testWidgets('groups employees by department when enabled', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger initState
    await tester.pump(); // Trigger microtask
    await tester.pumpAndSettle();

    // Toggle grouping
    await tester.tap(find.byTooltip('toggle_grouping'));
    await tester.pumpAndSettle();

    expect(find.text('ENGINEERING'), findsOneWidget); // Group header
    expect(find.text('HR'), findsNWidgets(2)); // Group header + Subtitle in tile
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Bob Wilson'), findsOneWidget);
  });

  testWidgets('groups are sorted by department name', (WidgetTester tester) async {
    final unsortedEmployees = [
      {'_id': '1', 'name': 'Bob', 'dept_id': 'd2', 'is_enrolled': true}, // HR
      {'_id': '2', 'name': 'Alice', 'dept_id': 'd1', 'is_enrolled': true}, // Engineering
    ];

    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(unsortedEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger initState
    await tester.pump(); // Trigger microtask
    await tester.pumpAndSettle();

    // Toggle grouping
    await tester.tap(find.byTooltip('toggle_grouping'));
    await tester.pumpAndSettle();

    // Verify Engineering (d1) comes before HR (d2)
    final engineeringFinder = find.text('ENGINEERING');
    final hrFinder = find.text('HR');

    expect(engineeringFinder, findsOneWidget);
    expect(hrFinder, findsNWidgets(2));

    final engineeringTop = tester.getTopLeft(engineeringFinder).dy;
    final hrTop = tester.getTopLeft(hrFinder.first).dy;

    expect(engineeringTop, lessThan(hrTop));
  });

  testWidgets('shows error message on failure', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode({'detail': 'Server error'}), 500));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger initState
    await tester.pump(); // Trigger microtask
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
  });

  testWidgets('filters employees by name search', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/employees/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockEmployees), 200));
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Bob Wilson'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'John');
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsNothing);
    expect(find.text('Bob Wilson'), findsNothing);
  });
}
