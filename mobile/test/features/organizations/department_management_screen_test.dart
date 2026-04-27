import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/organizations/department_management_screen.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';

import 'department_management_screen_test.mocks.dart';

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
        home: DepartmentManagementScreen(),
      ),
    );
  }

  final mockDepts = [
    {'_id': 'd1', 'name': 'Engineering'},
    {'_id': 'd2', 'name': 'HR'},
  ];

  testWidgets('renders department list', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('HR'), findsOneWidget);
  });

  testWidgets('creates a new department', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Marketing');
    
    when(mockClient.post(
      Uri.parse('http://localhost:8000/api/v1/departments/'),
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(jsonEncode({'_id': 'd3', 'name': 'Marketing'}), 201));

    // After success, it fetches again
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode([...mockDepts, {'_id': 'd3', 'name': 'Marketing'}]), 200));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Marketing'), findsOneWidget);
  });

  testWidgets('updates a department', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Software Engineering');

    when(mockClient.put(
      Uri.parse('http://localhost:8000/api/v1/departments/d1'),
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(jsonEncode({'_id': 'd1', 'name': 'Software Engineering'}), 200));

    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode([{'_id': 'd1', 'name': 'Software Engineering'}, mockDepts[1]]), 200));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Software Engineering'), findsOneWidget);
  });

  testWidgets('deletes a department', (WidgetTester tester) async {
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(mockDepts), 200));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    when(mockClient.delete(
      Uri.parse('http://localhost:8000/api/v1/departments/d1'),
      headers: anyNamed('headers'),
    )).thenAnswer((_) async => http.Response('', 204));

    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/departments/'),
            headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode([mockDepts[1]]), 200));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Engineering'), findsNothing);
    expect(find.text('HR'), findsOneWidget);
  });
}
