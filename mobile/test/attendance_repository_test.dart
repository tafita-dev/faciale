import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:faciale/features/attendance/attendance_repository.dart';
import 'package:faciale/features/attendance/offline_storage_service.dart';
import 'package:faciale/core/network/connectivity_provider.dart';

import 'attendance_repository_test.mocks.dart';

@GenerateMocks([http.Client, FlutterSecureStorage, OfflineStorageService])
void main() {
  late AttendanceRepository repository;
  late MockClient mockClient;
  late MockFlutterSecureStorage mockStorage;
  late MockOfflineStorageService mockOfflineStorage;

  setUp(() {
    mockClient = MockClient();
    mockStorage = MockFlutterSecureStorage();
    mockOfflineStorage = MockOfflineStorageService();
    repository = AttendanceRepository(
      mockClient, 
      mockStorage, 
      'http://api.test',
      offlineStorage: mockOfflineStorage,
    );
    // Create dummy file
    File('path.jpg').writeAsBytesSync([0]);
  });

  tearDown(() {
    if (File('path.jpg').existsSync()) {
      File('path.jpg').deleteSync();
    }
  });

  test('checkIn calls upload when online', () async {
    when(mockStorage.read(key: 'jwt_token')).thenAnswer((_) async => 'fake-token');
    when(mockClient.send(any)).thenAnswer((_) async {
      final response = http.StreamedResponse(
        Stream.value('{"success": true}'.codeUnits),
        200,
      );
      return response;
    });

    final result = await repository.checkIn('path.jpg', isOffline: false);

    expect(result['success'], true);
    verifyNever(mockOfflineStorage.saveScan(any, any));
  });

  test('checkIn saves locally when offline', () async {
    final result = await repository.checkIn('path.jpg', isOffline: true, forceType: 'entry');

    expect(result['success'], true);
    expect(result['message'], contains('saved locally'));
    expect(result['offline'], true);
    
    verify(mockOfflineStorage.saveScan('path.jpg', 'entry')).called(1);
    verifyNever(mockClient.send(any));
  });
}
