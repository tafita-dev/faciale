import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faciale/features/attendance/offline_storage_service.dart';
import 'package:path/path.dart' as p;

import 'offline_storage_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSharedPreferences mockPrefs;
  late OfflineStorageService service;
  late Directory mockPersistentDir;

  setUp(() async {
    mockPrefs = MockSharedPreferences();
    mockPersistentDir = await Directory.systemTemp.createTemp();
    
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return mockPersistentDir.path;
      }
      return null;
    });
        
    service = OfflineStorageService(mockPrefs);
  });

  tearDown(() async {
    await mockPersistentDir.delete(recursive: true);
  });

  test('saveScan moves image to persistent storage and saves metadata', () async {
    // Create a real temp file to copy from
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File(p.join(tempDir.path, 'source.jpg'));
    await tempFile.writeAsString('dummy content');
    
    when(mockPrefs.getString(any)).thenReturn(null);
    var savedData = '';
    when(mockPrefs.setString(any, captureAny)).thenAnswer((Invocation inv) async {
      savedData = inv.positionalArguments[1] as String;
      return true;
    });

    await service.saveScan(tempFile.path, 'entry');

    expect(savedData, contains('offline_scans/offline_'));
    expect(savedData, isNot(contains(tempFile.path)));
    
    // Verify file was actually copied
    final decoded = jsonDecode(savedData) as List;
    final newPath = decoded.first['imagePath'] as String;
    expect(await File(newPath).exists(), isTrue);
    
    // Cleanup
    await tempDir.delete(recursive: true);
  });

  test('saveScan throws error if source image does not exist', () async {
    const nonExistentPath = '/tmp/does_not_exist.jpg';
    
    expect(
      () => service.saveScan(nonExistentPath, 'entry'),
      throwsA(predicate((e) => e.toString().contains('Source image does not exist'))),
    );
  });
}
