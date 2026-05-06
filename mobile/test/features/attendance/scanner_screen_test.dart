import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/employees/camera_provider.dart';

void main() {
  testWidgets('ScannerScreen: Success/Failure modals and Processing overlay', (WidgetTester tester) async {
    // Mock camera description
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    // Set up method channel mock for SystemSound
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      return null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          camerasProvider.overrideWith((ref) => Future.value([camera])),
        ],
        child: const MaterialApp(
          home: ScannerScreen(),
        ),
      ),
    );

    final element = tester.element(find.byType(ScannerScreen));
    final container = ProviderScope.containerOf(element);

    // 1. Initial State: Scanning
    expect(find.text('ALIGN_YOUR_FACE'), findsOneWidget);

    // 2. Test Processing State: Global Overlay
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.processing,
      message: 'analyzing',
    );
    await tester.pump();
    
    // Check for global overlay text - Should NOT be present
    expect(find.text('ANALYZING'), findsNothing);
    // Camera should be hidden
    expect(find.byType(CameraPreview), findsNothing);

    // 3. Test Success State: Modal appears
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.success, 
      message: 'Success', 
      name: 'John Doe',
      type: 'entry',
      score: 0.95,
      uiColor: 'green'
    );
    
    // Pump several times to let the modal appear
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Modal title (from message)
    expect(find.text('SUCCESS'), findsOneWidget);
    // Employee name
    expect(find.text('John Doe'), findsOneWidget);
    // OK button
    expect(find.text('OK'), findsOneWidget);

    // 4. Test Success DOES auto-reset
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('OK'), findsNothing);
    // Should be back to scanning
    expect(find.text('ALIGN_YOUR_FACE'), findsOneWidget);

    // 5. Test Failure State: Modal appears
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.failure,
      message: 'failed',
      error: 'Too dark',
      uiColor: 'red'
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Should show FAILED in a dialog
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
    
    // Auto-reset failure too
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Dialog), findsNothing);
  });
}
