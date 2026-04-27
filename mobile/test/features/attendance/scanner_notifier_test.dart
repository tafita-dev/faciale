import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/scanner_state.dart';

@GenerateMocks([AttendanceRepository])
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

  test('ScannerNotifier starts in scanning state', () {
    final state = container.read(scannerProvider);
    expect(state.status, ScannerStatus.scanning);
    expect(state.message, 'Align your face');
  });

  test('processImage success updates state to success', () async {
    when(mockRepository.checkIn(any)).thenAnswer((_) async => {
      'success': true,
      'message': 'Success: John Doe checked in.',
      'data': {
        'employee_name': 'John Doe',
        'type': 'entry',
      }
    });

    final notifier = container.read(scannerProvider.notifier);
    await notifier.processImage('fake_path.jpg');

    final state = container.read(scannerProvider);
    expect(state.status, ScannerStatus.success);
    expect(state.matchedName, 'John Doe');
    expect(state.message, 'Success: John Doe checked in.');
  });

  test('processImage failure updates state to failure', () async {
    when(mockRepository.checkIn(any)).thenAnswer((_) async => {
      'success': false,
      'message': 'User not found.',
    });

    final notifier = container.read(scannerProvider.notifier);
    await notifier.processImage('fake_path.jpg');

    final state = container.read(scannerProvider);
    expect(state.status, ScannerStatus.failure);
    expect(state.error, 'User not found.');
  });
}
