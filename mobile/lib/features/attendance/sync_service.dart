import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendance_repository.dart';
import 'offline_storage_service.dart';
import '../auth/auth_provider.dart';
import '../../core/ux/ux_provider.dart';
import '../../core/network/connectivity_provider.dart';

class SyncService {
  final Ref _ref;
  bool _isSyncing = false;

  SyncService(this._ref);

  Future<void> sync() async {
    if (_isSyncing) return;
    
    final auth = _ref.read(authProvider);
    if (auth.token == null) return; // Must be authenticated to sync
    
    _isSyncing = true;

    try {
      final storage = _ref.read(offlineStorageServiceProvider);
      final repository = _ref.read(attendanceRepositoryProvider);
      final ux = _ref.read(uxProvider.notifier);

      final scans = storage.getPendingScans();
      if (scans.isEmpty) return;

      int successCount = 0;
      for (final scan in scans) {
        final imagePath = scan['imagePath'] as String;
        final forceType = scan['forceType'] as String?;
        final timestamp = scan['timestamp'] as String?;
        final scanOrgId = scan['orgId'] as String?;

        // Only sync if orgId matches or if scan has no orgId (legacy)
        if (scanOrgId != null && auth.orgId != null && scanOrgId != auth.orgId) {
          continue; 
        }

        try {
          final result = await repository.checkIn(
            imagePath,
            forceType: forceType,
            isOffline: false,
            timestamp: timestamp,
          );

          if (result['success'] == true) {
            await storage.removeScan(imagePath);
            successCount++;
          }
        } catch (e) {
          // Log error and continue with next scan
          debugPrint('Error syncing scan $imagePath: $e');
        }
      }

      if (successCount > 0) {
        ux.showSuccess('records_synced_successfully', args: [successCount.toString()]);
      }
    } finally {
      _isSyncing = false;
    }
  }
}

final syncServiceProvider = Provider((ref) {
  final service = SyncService(ref);
  
  // Listen for connectivity changes
  ref.listen(connectivityProvider, (previous, next) {
    next.whenData((status) {
      if (status == ConnectivityStatus.isConnected) {
        service.sync();
      }
    });
  });
  
  return service;
});
