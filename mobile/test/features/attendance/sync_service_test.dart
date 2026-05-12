import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:faciale/features/attendance/sync_service.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/offline_storage_service.dart';
import 'package:faciale/core/network/connectivity_provider.dart';
import 'package:faciale/core/ux/ux_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([AttendanceRepository, OfflineStorageService])
void main() {
  late MockAttendanceRepository mockRepo;
  late MockOfflineStorageService mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAttendanceRepository();
    mockStorage = MockOfflineStorageService();

    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepo),
        offlineStorageServiceProvider.overrideWithValue(mockStorage),
        authProvider.overrideWith(() => AuthNotifierMock(AuthState(token: 'valid_token', orgId: 'org1'))),
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.isConnected)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('SyncService syncs when connectivity changes to isConnected', () async {
    // 1. Arrange
    final pendingScans = [
      {'imagePath': 'path1.jpg', 'forceType': 'entry', 'timestamp': '2023-01-01T10:00:00Z', 'orgId': 'org1'},
      {'imagePath': 'path2.jpg', 'forceType': 'exit', 'timestamp': '2023-01-01T10:05:00Z', 'orgId': 'org1'},
    ];

    when(mockStorage.getPendingScans()).thenReturn(pendingScans);
    when(mockRepo.checkIn(any, 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')))
        .thenAnswer((_) async => {'success': true, 'data': {}});

    // 2. Act
    final syncService = container.read(syncServiceProvider);
    await syncService.sync();

    // 3. Assert
    verify(mockRepo.checkIn('path1.jpg', forceType: 'entry', isOffline: false, timestamp: '2023-01-01T10:00:00Z')).called(1);
    verify(mockRepo.checkIn('path2.jpg', forceType: 'exit', isOffline: false, timestamp: '2023-01-01T10:05:00Z')).called(1);
    verify(mockStorage.removeScan('path1.jpg')).called(1);
    verify(mockStorage.removeScan('path2.jpg')).called(1);
    
    final uxState = container.read(uxProvider);
    expect(uxState.message?.text, equals('records_synced_successfully'));
    expect(uxState.message?.args, equals(['2']));
  });

  test('SyncService keeps record if sync fails', () async {
    // 1. Arrange
    final pendingScans = [
      {'imagePath': 'path1.jpg', 'forceType': 'entry', 'timestamp': '2023-01-01T10:00:00Z', 'orgId': 'org1'},
    ];

    when(mockStorage.getPendingScans()).thenReturn(pendingScans);
    when(mockRepo.checkIn(any, 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')))
        .thenAnswer((_) async => {'success': false, 'message': 'Server Error'});

    // 2. Act
    final syncService = container.read(syncServiceProvider);
    await syncService.sync();

    // 3. Assert
    verify(mockRepo.checkIn('path1.jpg', forceType: 'entry', isOffline: false, timestamp: '2023-01-01T10:00:00Z')).called(1);
    verifyNever(mockStorage.removeScan(any));
    
    final uxState = container.read(uxProvider);
    expect(uxState.message, isNull);
  });

  test('SyncService continues to next scan if one throws an exception', () async {
    // 1. Arrange
    final pendingScans = [
      {'imagePath': 'fail.jpg', 'forceType': 'entry', 'timestamp': '2023-01-01T10:00:00Z', 'orgId': 'org1'},
      {'imagePath': 'success.jpg', 'forceType': 'exit', 'timestamp': '2023-01-01T10:05:00Z', 'orgId': 'org1'},
    ];

    when(mockStorage.getPendingScans()).thenReturn(pendingScans);
    
    // First call throws
    when(mockRepo.checkIn('fail.jpg', 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')))
        .thenThrow(Exception('Network Error'));
        
    // Second call succeeds
    when(mockRepo.checkIn('success.jpg', 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')))
        .thenAnswer((_) async => {'success': true, 'data': {}});

    // 2. Act
    final syncService = container.read(syncServiceProvider);
    await syncService.sync();

    // 3. Assert
    verify(mockRepo.checkIn('fail.jpg', forceType: 'entry', isOffline: false, timestamp: '2023-01-01T10:00:00Z')).called(1);
    verify(mockRepo.checkIn('success.jpg', forceType: 'exit', isOffline: false, timestamp: '2023-01-01T10:05:00Z')).called(1);
    
    verifyNever(mockStorage.removeScan('fail.jpg'));
    verify(mockStorage.removeScan('success.jpg')).called(1);
    
    final uxState = container.read(uxProvider);
    expect(uxState.message?.args, equals(['1']));
  });

  test('SyncService filters scans by orgId', () async {
    // 1. Arrange
    final pendingScans = [
      {'imagePath': 'mine.jpg', 'forceType': 'entry', 'timestamp': '2023-01-01T10:00:00Z', 'orgId': 'org1'},
      {'imagePath': 'other.jpg', 'forceType': 'exit', 'timestamp': '2023-01-01T10:05:00Z', 'orgId': 'other_org'},
    ];

    when(mockStorage.getPendingScans()).thenReturn(pendingScans);
    when(mockRepo.checkIn(any, 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')))
        .thenAnswer((_) async => {'success': true, 'data': {}});

    // 2. Act
    final syncService = container.read(syncServiceProvider);
    await syncService.sync();

    // 3. Assert
    verify(mockRepo.checkIn('mine.jpg', forceType: 'entry', isOffline: false, timestamp: '2023-01-01T10:00:00Z')).called(1);
    verifyNever(mockRepo.checkIn('other.jpg', forceType: anyNamed('forceType'), isOffline: anyNamed('isOffline'), timestamp: anyNamed('timestamp')));
    
    verify(mockStorage.removeScan('mine.jpg')).called(1);
    verifyNever(mockStorage.removeScan('other.jpg'));
    
    final uxState = container.read(uxProvider);
    expect(uxState.message?.args, equals(['1']));
  });

  test('SyncService does not sync if not authenticated', () async {
    // 1. Arrange
    final unauthContainer = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepo),
        offlineStorageServiceProvider.overrideWithValue(mockStorage),
        authProvider.overrideWith(() => AuthNotifierMock(AuthState())), // No token
        connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityStatus.isConnected)),
      ],
    );

    when(mockStorage.getPendingScans()).thenReturn([
      {'imagePath': 'path1.jpg', 'orgId': 'org1'}
    ]);

    // 2. Act
    final syncService = unauthContainer.read(syncServiceProvider);
    await syncService.sync();

    // 3. Assert
    verifyNever(mockRepo.checkIn(any, 
            forceType: anyNamed('forceType'), 
            isOffline: anyNamed('isOffline'),
            timestamp: anyNamed('timestamp')));
    
    unauthContainer.dispose();
  });
}

class AuthNotifierMock extends AuthNotifier {
  final AuthState initialState;
  AuthNotifierMock(this.initialState);
  
  @override
  AuthState build() => initialState;
}
