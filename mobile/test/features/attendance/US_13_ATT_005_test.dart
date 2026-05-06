import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:faciale/features/employees/camera_provider.dart';
import 'package:camera/camera.dart';
import 'US_13_ATT_003_test.mocks.dart';

void main() {
  late MockAttendanceRepository mockRepository;

  setUp(() {
    mockRepository = MockAttendanceRepository();
  });

  testWidgets('US-13-ATT-005: Default mode is Auto and can switch to Entry/Exit', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
        camerasProvider.overrideWith((ref) => Future.value([
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 90,
          )
        ])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ScannerScreen()),
      ),
    );

    await tester.pump();

    // AC Scenario 1: Default to Auto Mode
    expect(container.read(scannerProvider).scanningMode, ScanningMode.auto);
    expect(find.text('AUTO'), findsOneWidget);

    // AC Scenario 2: Switch to Entry Only
    // Assuming we have a button or toggle to switch modes
    // Let's look for a button with 'AUTO' and tap it to change
    await tester.tap(find.text('AUTO'));
    await tester.pump();
    
    expect(container.read(scannerProvider).scanningMode, ScanningMode.entry);
    expect(find.text('ENTRY'), findsOneWidget);

    // AC Scenario 3: Switch to Exit Only
    await tester.tap(find.text('ENTRY'));
    await tester.pump();
    
    expect(container.read(scannerProvider).scanningMode, ScanningMode.exit);
    expect(find.text('EXIT'), findsOneWidget);
  });

  test('US-13-ATT-005: processImage sends force_type based on mode', () async {
     final mockRepository = MockAttendanceRepository();
     final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    final notifier = container.read(scannerProvider.notifier);

    // 1. Test Auto mode (no force_type)
    when(mockRepository.checkIn(any, forceType: null)).thenAnswer((_) async => {'success': true, 'data': {}});
    await notifier.processImage('path');
    verify(mockRepository.checkIn(any, forceType: null)).called(1);

    notifier.reset();

    // 2. Test Entry mode
    notifier.setScanningMode(ScanningMode.entry);
    when(mockRepository.checkIn(any, forceType: 'entry')).thenAnswer((_) async => {'success': true, 'data': {}});
    await notifier.processImage('path');
    verify(mockRepository.checkIn(any, forceType: 'entry')).called(1);

    notifier.reset();

    // 3. Test Exit mode
    notifier.setScanningMode(ScanningMode.exit);
    when(mockRepository.checkIn(any, forceType: 'exit')).thenAnswer((_) async => {'success': true, 'data': {}});
    await notifier.processImage('path');
    verify(mockRepository.checkIn(any, forceType: 'exit')).called(1);
  });
}
