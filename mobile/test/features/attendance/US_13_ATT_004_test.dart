import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:fake_async/fake_async.dart';
import 'package:faciale/features/employees/camera_provider.dart';
import 'package:camera/camera.dart';
import 'US_13_ATT_003_test.mocks.dart';

void main() {
  late MockAttendanceRepository mockRepository;

  setUp(() {
    mockRepository = MockAttendanceRepository();
  });

  testWidgets('AC Scenario 1: Processing state has minimalist loader without text', (WidgetTester tester) async {
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

    // Set status to processing
    container.read(scannerProvider.notifier).setStatus(ScannerStatus.processing);
    await tester.pump();

    // Verify loader is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Verify NO text is displayed with the loader
    // The previous implementation had "ANALYZING..."
    expect(find.textContaining('ANALYZING'), findsNothing);
  });

  test('AC Scenario 2 & 3: Success auto-resets after 3 seconds', () {
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    fakeAsync((async) {
      when(mockRepository.checkIn(any)).thenAnswer((_) async => {
        'success': true,
        'message': 'Bienvenue John',
        'ui': {'color': 'green'},
        'data': {
          'employee_name': 'John',
          'type': 'entry',
        }
      });

      final notifier = container.read(scannerProvider.notifier);
      notifier.processImage('fake_path.jpg');
      
      async.flushMicrotasks();
      
      final state = container.read(scannerProvider);
      expect(state.status, ScannerStatus.success);

      // Advance time by 4 seconds (reset is at 3s)
      async.elapse(const Duration(seconds: 4));
      
      // Should be back to scanning automatically (Current implementation does NOT auto-reset success)
      expect(container.read(scannerProvider).status, ScannerStatus.scanning);
    });
  });
}
