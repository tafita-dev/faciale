import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faciale/features/attendance/offline_storage_service.dart';
import 'dart:io';

@GenerateMocks([SharedPreferences])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('OfflineStorageService', () {
    late OfflineStorageService service;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp();
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OfflineStorageService(prefs);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saveScan stores metadata in shared preferences', () async {
      // Create a real file to copy
      final sourceFile = File('${tempDir.path}/source.jpg');
      await sourceFile.writeAsString('test');

      await service.saveScan(sourceFile.path, 'entry', orgId: 'org1', userId: 'user1');
      
      final pending = service.getPendingScans();
      expect(pending.length, 1);
      expect(pending.first['imagePath'], contains('offline_scans/offline_'));
      expect(pending.first['forceType'], 'entry');
      expect(pending.first['orgId'], 'org1');
      expect(pending.first['userId'], 'user1');
      expect(pending.first['timestamp'], isNotNull);
    });

    test('getPendingScansCount returns correct count', () async {
      expect(service.getPendingScansCount(), 0);
      
      final file1 = File('${tempDir.path}/1.jpg');
      await file1.writeAsString('1');
      final file2 = File('${tempDir.path}/2.jpg');
      await file2.writeAsString('2');

      await service.saveScan(file1.path, null);
      await service.saveScan(file2.path, null);
      
      expect(service.getPendingScansCount(), 2);
    });
  });
}
