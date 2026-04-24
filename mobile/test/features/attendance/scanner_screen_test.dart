import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/employees/camera_provider.dart';

void main() {
  testWidgets('ScannerScreen shows Face Oval and transitions states', (WidgetTester tester) async {
    // Mock camera description
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 90,
    );

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

    // 1. Initial State: Scanning
    expect(find.text('Align your face'), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeast(1));

    // 2. Test Success State
    final element = tester.element(find.byType(ScannerScreen));
    final container = ProviderScope.containerOf(element);
    
    // Set up method channel mock for SystemSound
    final List<MethodCall> log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.success, 
      message: 'Matched', 
      name: 'John Doe'
    );
    
    await tester.pump();
    
    expect(find.text('Success!'), findsOneWidget);
    expect(find.text('John Doe - ${DateTime.now().hour}:${DateTime.now().minute}'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Verify beep was called
    expect(log, contains(
      isA<MethodCall>()
        .having((m) => m.method, 'method', 'SystemSound.play')
        .having((m) => m.arguments, 'arguments', 'SystemSoundType.click'),
    ));

    // 3. Test Processing State
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.processing,
      message: 'Analyzing...',
    );
    await tester.pump();
    expect(find.text('Analyzing...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

    // 4. Test Failure State
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.failure,
      message: 'Failed',
      error: 'Spoof detected'
    );
    await tester.pump();
    expect(find.text('Failed'), findsAtLeast(1));
    expect(find.text('Spoof detected'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);

    // 5. Test Auto-Reset after success
    container.read(scannerProvider.notifier).setStatus(
      ScannerStatus.success,
      message: 'Matched',
      name: 'Jane Doe'
    );
    await tester.pump();
    expect(find.text('Success!'), findsOneWidget);

    // Wait for 2 seconds
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // trigger rebuild after timer

    expect(find.text('Align your face'), findsOneWidget);
    expect(find.text('Success!'), findsNothing);
  });
}
