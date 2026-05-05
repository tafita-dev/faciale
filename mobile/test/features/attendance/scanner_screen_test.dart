import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/employees/camera_provider.dart';

void main() {
  testWidgets('ScannerScreen Hotfix: Success modal and Processing overlay', (WidgetTester tester) async {
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
    
    // Check for global overlay text
    expect(find.text('ANALYZING'), findsOneWidget);
    // Camera should be hidden
    expect(find.byType(CameraPreview), findsNothing);

    // 3. Test Success State: Modal appears
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.success, 
      message: 'Success', 
      name: 'John Doe',
      type: 'entry',
      score: 0.95
    );
    
    // Pump several times to let the modal appear
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Modal title
    expect(find.text('SUCCESS'), findsOneWidget);
    // Employee name
    expect(find.text('John Doe'), findsOneWidget);
    // OK button
    expect(find.text('OK'), findsOneWidget);

    // 4. Test Success does NOT auto-reset
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('OK'), findsOneWidget);

    // 5. Test OK button resets state
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // wait for modal to close
    
    // Modal should be gone
    expect(find.text('OK'), findsNothing);
    // Should be back to scanning
    expect(find.text('ALIGN_YOUR_FACE'), findsOneWidget);

    // 6. Test Failure State: Existing UI preserved (no modal)
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.failure,
      message: 'failed',
      error: 'Too dark'
    );
    await tester.pump();
    
    // Should show failure card in the column
    expect(find.text('FAILED'), findsOneWidget);
    // Should NOT be a dialog (modal)
    expect(find.byType(Dialog), findsNothing);
  });
}
