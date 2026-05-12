import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class OfflineStorageService {
  final SharedPreferences _prefs;
  static const String _storageKey = 'pending_scans';

  OfflineStorageService(this._prefs);

  Future<void> saveScan(String imagePath, String? forceType, {String? orgId, String? userId}) async {
    // 1. Get persistent directory
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline_scans'));
    
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }

    // 2. Generate unique name and move file
    final fileName = 'offline_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = p.join(offlineDir.path, fileName);
    
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Source image does not exist: $imagePath');
      }
      await file.copy(newPath);
      // Optional: delete original if it's in temp
      // await file.delete(); 
    } catch (e) {
      if (e.toString().contains('No space left on device') || e.toString().contains('disk full')) {
        throw Exception('Storage full. Scan could not be saved.');
      }
      rethrow;
    }

    // 3. Save metadata with the NEW path
    final scans = _getScans();
    scans.add({
      'imagePath': newPath,
      'forceType': forceType,
      'orgId': orgId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(_storageKey, jsonEncode(scans));
  }

  Future<void> removeScan(String imagePath) async {
    final scans = _getScans();
    final index = scans.indexWhere((s) => s['imagePath'] == imagePath);
    if (index != -1) {
      final scan = scans.removeAt(index);
      await _prefs.setString(_storageKey, jsonEncode(scans));
      
      // Delete the file
      try {
        final file = File(scan['imagePath']);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Log error but don't fail removal from metadata
        print('Error deleting offline scan file: $e');
      }
    }
  }

  int getPendingScansCount() {
    return _getScans().length;
  }

  List<Map<String, dynamic>> getPendingScans() {
    return _getScans();
  }

  List<Map<String, dynamic>> _getScans() {
    final data = _prefs.getString(_storageKey);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }

  Future<void> clearScans() async {
    await _prefs.remove(_storageKey);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart');
});

final offlineStorageServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineStorageService(prefs);
});

class PendingScansNotifier extends Notifier<int> {
  @override
  int build() {
    final service = ref.watch(offlineStorageServiceProvider);
    return service.getPendingScansCount();
  }

  void refresh() {
    final service = ref.read(offlineStorageServiceProvider);
    state = service.getPendingScansCount();
  }
}

final pendingScansCountProvider = NotifierProvider<PendingScansNotifier, int>(() {
  return PendingScansNotifier();
});
