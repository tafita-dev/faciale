import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/main.dart';
import 'package:faciale/core/ux/ux_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000\n');
  });

  testWidgets('Global UX overlay shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FacialeApp(),
      ),
    );

    // Get the container to access the provider
    final element = tester.element(find.byType(FacialeApp));
    final container = ProviderScope.containerOf(element);

    // Initial state: no loading
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Trigger loading
    container.read(uxProvider.notifier).showLoading('Processing...');
    await tester.pump();

    // Verify loading overlay
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Processing...'), findsOneWidget);

    // Hide loading
    container.read(uxProvider.notifier).hideLoading();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Global UX shows snackbar for messages', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FacialeApp(),
      ),
    );

    final element = tester.element(find.byType(FacialeApp));
    final container = ProviderScope.containerOf(element);

    // Trigger success message
    container.read(uxProvider.notifier).showSuccess('Operation successful');
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // Wait for snackbar to appear

    // Verify snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Operation successful'), findsOneWidget);
  });
}
