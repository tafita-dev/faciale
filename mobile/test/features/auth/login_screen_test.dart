import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/auth/login_screen.dart';
import 'package:faciale/core/theme.dart';
import 'package:faciale/features/auth/auth_provider.dart';

void main() {
  testWidgets('Login Screen UI Elements Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.face), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('Successful Login redirect placeholder test', (WidgetTester tester) async {
    // Note: To test redirection with go_router, we should ideally use the actual router.
    // For this test, we'll verify the loading spinner and interaction.
    
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'admin@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password');
    
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump(); // Start of animation/loading

    // Verify loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Wait for the mock delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(); 

    // Since we are not in the real router context in this test, 
    // we can't easily verify context.go('/dashboard').
    // But we can verify that the button is enabled again or similar if it stayed on screen.
  });

  testWidgets('Invalid Credentials shows snackbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'wrong@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
