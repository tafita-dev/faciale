import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/attendance/scanner_state.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/face_detector_service.dart';
import 'package:faciale/features/attendance/offline_storage_service.dart';
import 'package:faciale/core/network/connectivity_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'scanner_offline_test.mocks.dart';

@GenerateMocks([AttendanceRepository, FaceDetectorService, Face, OfflineStorageService, http.Client, FlutterSecureStorage])
void main() {
  late MockAttendanceRepository mockRepository;
  late MockFaceDetectorService mockFaceDetector;
  late MockOfflineStorageService mockOfflineStorage;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockFaceDetector = MockFaceDetectorService();
    mockOfflineStorage = MockOfflineStorageService();
  });

  test('ScannerNotifier calls checkIn with isOffline=true when disconnected', () async {
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepository),
        faceDetectorServiceProvider.overrideWithValue(mockFaceDetector),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.isDisconnected)),
        offlineStorageServiceProvider.overrideWithValue(mockOfflineStorage),
      ],
    );

    container.listen(connectivityProvider, (previous, next) {}, fireImmediately: true);
    await pumpEventQueue();

    final notifier = container.read(scannerProvider.notifier);
    
    final mockFace = MockFace();
    when(mockFace.leftEyeOpenProbability).thenReturn(0.6);
    when(mockFace.rightEyeOpenProbability).thenReturn(0.6);
    when(mockFace.headEulerAngleX).thenReturn(0.0);
    when(mockFace.headEulerAngleY).thenReturn(0.0);
    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [mockFace]);

    when(mockRepository.checkIn(any, forceType: anyNamed('forceType'), isOffline: true))
        .thenAnswer((_) async => {
          'success': true,
          'message': 'Scan saved locally (Offline)',
          'offline': true,
        });

    await notifier.processImage('test_path.jpg');

    verify(mockRepository.checkIn('test_path.jpg', forceType: null, isOffline: true)).called(1);
    expect(container.read(scannerProvider).status, ScannerStatus.success);
  });

  test('pendingScansCountProvider updates after offline checkIn', () async {
    when(mockOfflineStorage.getPendingScansCount()).thenReturn(0);

    final container = ProviderContainer(
      overrides: [
        offlineStorageServiceProvider.overrideWithValue(mockOfflineStorage),
        faceDetectorServiceProvider.overrideWithValue(mockFaceDetector),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.isDisconnected)),
        // We need to use the real repository but with mocked dependencies to test the callback
        attendanceRepositoryProvider.overrideWith((ref) => AttendanceRepository(
          MockClient(),
          MockFlutterSecureStorage(),
          'http://api',
          offlineStorage: mockOfflineStorage,
          onOfflineSave: () => ref.read(pendingScansCountProvider.notifier).refresh(),
        )),
      ],
    );

    container.listen(connectivityProvider, (previous, next) {}, fireImmediately: true);
    await pumpEventQueue();

    expect(container.read(pendingScansCountProvider), 0);

    // Mock face detection
    final mockFace = MockFace();
    when(mockFace.leftEyeOpenProbability).thenReturn(0.6);
    when(mockFace.rightEyeOpenProbability).thenReturn(0.6);
    when(mockFace.headEulerAngleX).thenReturn(0.0);
    when(mockFace.headEulerAngleY).thenReturn(0.0);
    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [mockFace]);

    // Mock saving
    when(mockOfflineStorage.saveScan(any, any)).thenAnswer((_) async {
      when(mockOfflineStorage.getPendingScansCount()).thenReturn(1);
    });

    await container.read(scannerProvider.notifier).processImage('test_path.jpg');

    expect(container.read(pendingScansCountProvider), 1);
  });

  test('ScannerNotifier shows error when storage is full', () async {
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWith((ref) => AttendanceRepository(
          MockClient(),
          MockFlutterSecureStorage(),
          'http://api',
          offlineStorage: mockOfflineStorage,
        )),
        faceDetectorServiceProvider.overrideWithValue(mockFaceDetector),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.isDisconnected)),
        offlineStorageServiceProvider.overrideWithValue(mockOfflineStorage),
      ],
    );

    container.listen(connectivityProvider, (previous, next) {}, fireImmediately: true);
    await pumpEventQueue();

    // Mock face detection
    final mockFace = MockFace();
    when(mockFace.leftEyeOpenProbability).thenReturn(0.6);
    when(mockFace.rightEyeOpenProbability).thenReturn(0.6);
    when(mockFace.headEulerAngleX).thenReturn(0.0);
    when(mockFace.headEulerAngleY).thenReturn(0.0);
    when(mockFaceDetector.detectFaces(any)).thenAnswer((_) async => [mockFace]);

    // Mock storage full exception
    when(mockOfflineStorage.saveScan(any, any)).thenThrow(Exception('disk full'));

    await container.read(scannerProvider.notifier).processImage('test_path.jpg');

    final state = container.read(scannerProvider);
    expect(state.status, ScannerStatus.failure);
    expect(state.error, contains('Storage full'));
  });
}
