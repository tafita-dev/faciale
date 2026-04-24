import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:faciale/features/employees/enroll_screen.dart';
import 'package:faciale/features/employees/camera_actions.dart';

void main() {
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
    expect(find.text('Employee Enrollment'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget); // Name field
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget); // Dept field
    expect(find.text('Capture Reference Photo'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // 1. Trigger validation without any data
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter name'), findsOneWidget);
    expect(find.text('Please select department'), findsOneWidget);
    
    // 2. Fill fields but no photo
    await tester.enterText(find.byType(TextFormField), 'John Doe');
    // Select department
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please capture a reference photo'), findsOneWidget);

    // 3. Capture photo and save
    await tester.tap(find.text('Capture Reference Photo'));
    await tester.pumpAndSettle();
    
    expect(find.text('Photo Captured!'), findsOneWidget);
    
    await tester.tap(find.text('Save'));
    await tester.pump();
    
    expect(find.text('Generating Secure Identity...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // Verify redirection to Employee List
    expect(find.text('Employee List'), findsOneWidget);
    expect(find.byType(EnrollScreen), findsNothing);
  });
}
