import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';
import 'package:faciale/features/employees/enroll_screen.dart';
import 'package:faciale/features/employees/camera_actions.dart';
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capturePhotoProvider.overrideWithValue((context) async => 'fake_path.jpg'),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Verify UI elements
    expect(find.text('employee_enrollment'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget); // Name field
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget); // Dept field
    expect(find.text('capture_reference_photo'), findsOneWidget);
    expect(find.widgetWithText(NeumorphicButton, 'SAVE'), findsOneWidget);

    // 1. Trigger validation without any data
    await tester.tap(find.widgetWithText(NeumorphicButton, 'SAVE'));
    await tester.pump();

    expect(find.text('please_enter_name'), findsOneWidget);
    expect(find.text('please_select_department'), findsOneWidget);
    
    // 2. Fill fields but no photo
    await tester.enterText(find.byType(TextFormField), 'John Doe');
    // Select department
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    
    // Mock departments would be needed for the dropdown to have items
    // But since it's a unit-ish widget test, we might need to override the department provider
  });
}
