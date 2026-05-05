import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:fake_async/fake_async.dart';
import 'scanner_notifier_test.mocks.dart';

void main() {
  late MockAttendanceRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('processImage success populates new fields and does not auto-reset', () {
    fakeAsync((async) {
      when(mockRepository.checkIn(any)).thenAnswer((_) async => {
        'success': true,
        'message': 'Success: John Doe checked in.',
        'data': {
          'employee_name': 'John Doe',
          'type': 'entry',
          'score': 0.98,
        }
      });

      final notifier = container.read(scannerProvider.notifier);
      notifier.processImage('fake_path.jpg');
      
      async.flushMicrotasks();
      
      final state = container.read(scannerProvider);
      expect(state.status, ScannerStatus.success);
      expect(state.matchedName, 'John Doe');
      expect(state.checkInType, 'entry');
      expect(state.score, 0.98);

      // Advance time by 5 seconds
      async.elapse(const Duration(seconds: 5));
      
      // Should still be in success state (no auto-reset)
      expect(container.read(scannerProvider).status, ScannerStatus.success);
    });
  });

  test('processImage failure still auto-resets', () {
    fakeAsync((async) {
      when(mockRepository.checkIn(any)).thenAnswer((_) async => {
        'success': false,
        'message': 'Face not recognized.',
      });

      final notifier = container.read(scannerProvider.notifier);
      notifier.processImage('fake_path.jpg');
      
      async.flushMicrotasks();
      
      expect(container.read(scannerProvider).status, ScannerStatus.failure);

      // Advance time by 4 seconds (reset is at 3s)
      async.elapse(const Duration(seconds: 4));
      
      // Should be back to scanning
      expect(container.read(scannerProvider).status, ScannerStatus.scanning);
    });
  });

  test('processImage ignores simultaneous calls', () async {
    final notifier = container.read(scannerProvider.notifier);
    
    // Mock a slow repository call
    when(mockRepository.checkIn(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return {
        'success': true,
        'data': {'employee_name': 'John Doe', 'type': 'entry'}
      };
    });

    // Fire two calls simultaneously
    final firstCall = notifier.processImage('path1.jpg');
    final secondCall = notifier.processImage('path2.jpg');
    
    await Future.wait([firstCall, secondCall]);
    
    // verify repository was called EXACTLY once
    verify(mockRepository.checkIn(any)).called(1);
    expect(container.read(scannerProvider).status, ScannerStatus.success);
  });
}
