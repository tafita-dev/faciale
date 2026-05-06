import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:faciale/features/attendance/scanner_screen.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/attendance/face_oval_painter.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/employees/camera_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'US_13_ATT_003_test.mocks.dart';

@GenerateMocks([AttendanceRepository])
void main() {
  late MockAttendanceRepository mockRepository;

  setUp(() {
    mockRepository = MockAttendanceRepository();
  });

  testWidgets('US-13-ATT-003: Immersive mode and Visual guides', (WidgetTester tester) async {
    const camera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 90,
    );

    final methodCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      methodCalls.add(methodCall);
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

    // AC Scenario 1: Immersive View
    final immersiveCall = methodCalls.firstWhere(
      (call) => call.method == 'SystemChrome.setEnabledSystemUIMode',
      orElse: () => throw Exception('setEnabledSystemUIMode not called'),
    );
    expect(immersiveCall.arguments, contains('immersiveSticky'));

    // AC Scenario 2: Visual Guides
    expect(find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is FaceOvalPainter), findsOneWidget);

    // Verify dispose restores edgeToEdge
    await tester.pumpWidget(Container()); // Dispose ScannerScreen
    final restoreCall = methodCalls.lastWhere(
      (call) => call.method == 'SystemChrome.setEnabledSystemUIMode' && call.arguments == 'SystemUiMode.edgeToEdge',
      orElse: () => throw Exception('edgeToEdge not restored on dispose'),
    );
    expect(restoreCall, isNotNull);
  });

  test('US-13-ATT-003: Double scan prevention logic', () async {
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    when(mockRepository.checkIn(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 50));
      return {'success': true, 'message': 'Success', 'data': {'employee_name': 'John', 'type': 'entry'}};
    });

    final notifier = container.read(scannerProvider.notifier);

    // Trigger first scan
    final future1 = notifier.processImage('path1');
    // Trigger second scan immediately
    final future2 = notifier.processImage('path2');

    await Future.wait([future1, future2]);

    // Verify repository was only called ONCE
    verify(mockRepository.checkIn('path1')).called(1);
    verifyNever(mockRepository.checkIn('path2'));
    
    container.dispose();
  });
}
