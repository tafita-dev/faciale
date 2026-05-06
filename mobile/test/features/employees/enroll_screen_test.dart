import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';
import 'package:faciale/features/employees/enroll_screen.dart';
import 'package:faciale/features/employees/camera_actions.dart';
import 'package:faciale/features/employees/employee_provider.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:faciale/core/ux/ux_provider.dart';
import 'package:faciale/core/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
  });

  testWidgets('EnrollScreen shows global loading overlay during submission', (WidgetTester tester) async {
    final mockDept = Department(id: 'd1', name: 'Engineering');
    
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const EnrollScreen(),
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) => const Scaffold(body: Text('Employees List')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capturePhotoProvider.overrideWithValue((context) async => 'fake_path.jpg'),
          departmentProvider.overrideWith(() => MockDeptNotifier([mockDept])),
          employeeProvider.overrideWith(() => MockEmployeeNotifier()),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final ux = ref.watch(uxProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
              builder: (context, child) {
                return Stack(
                  children: [
                    child!,
                    if (ux.isLoading)
                      const Positioned.fill(
                        child: Material(
                          color: Colors.black26,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill Name
    await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
    
    // Fill Email
    await tester.enterText(find.byType(TextFormField).at(1), 'john@test.com');
    
    // Select department
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    // Capture photo
    await tester.tap(find.text('capture_reference_photo'));
    await tester.pump();

    // Submit
    final saveButton = find.widgetWithText(NeumorphicButton, 'SAVE');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump(); // Start loading
    
    // Verify global loading overlay
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pumpAndSettle();
    expect(find.text('Employees List'), findsOneWidget);
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

class MockEmployeeNotifier extends EmployeeNotifier {
  @override
  EmployeeState build() {
    return EmployeeState();
  }

  @override
  Future<void> createAndEnrollEmployee({
    required String name,
    required String deptId,
    String? email,
    required String imagePath,
  }) async {
    final ux = ref.read(uxProvider.notifier);
    ux.showLoading('generating');
    await Future.delayed(const Duration(milliseconds: 100));
    ux.hideLoading();
    state = state.copyWith(isSuccess: true);
  }
}
