import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';
import 'package:faciale/features/employees/enroll_screen.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
  });

  testWidgets('EnrollScreen shows form and handles validation', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/enroll',
      routes: [
        GoRoute(
          path: '/enroll',
          builder: (context, state) => const EnrollScreen(),
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) => const Scaffold(body: Text('Employee List')),
        ),
      ],
    );

    final mockDept = Department(id: 'd1', name: 'Engineering');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capturePhotoProvider.overrideWithValue((context) async => 'fake_path.jpg'),
          departmentProvider.overrideWith(() => MockDeptNotifier([mockDept])),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI elements
    expect(find.text('employee_enrollment'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Name and Email fields
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget); // Dept field
    expect(find.text('capture_reference_photo'), findsOneWidget);
    expect(find.widgetWithText(NeumorphicButton, 'SAVE'), findsOneWidget);

    // 1. Trigger validation without any data
    final saveButton = find.widgetWithText(NeumorphicButton, 'SAVE');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('please_enter_name'), findsOneWidget);
    expect(find.text('please_select_department'), findsOneWidget);
    
    // 2. Fill fields
    final nameField = find.widgetWithText(TextFormField, 'full_name');
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'John Doe');
    
    final emailField = find.widgetWithText(TextFormField, 'email');
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'john@test.com');
    
    // Select department
    final deptDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(deptDropdown);
    await tester.tap(deptDropdown);
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    // Capture photo
    final photoBox = find.text('capture_reference_photo');
    await tester.ensureVisible(photoBox);
    await tester.tap(photoBox);
    await tester.pump();

    expect(find.text('photo_captured'), findsOneWidget);

    // Submit
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should redirect to employees list (mocked as text 'Employee List')
    expect(find.text('Employee List'), findsOneWidget);
  });
}

class MockDeptNotifier extends DepartmentNotifier {
  final List<Department> initialDepartments;
  MockDeptNotifier(this.initialDepartments);

  @override
  DeptState build() {
    return DeptState(departments: initialDepartments);
  }

  @override
  Future<void> fetchDepartments() async {}
}
