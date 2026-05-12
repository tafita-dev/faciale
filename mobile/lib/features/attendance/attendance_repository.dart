import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_provider.dart';
import 'package:http_parser/http_parser.dart'; 
import 'offline_storage_service.dart';

class AttendanceRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;
  final OfflineStorageService? _offlineStorage;
  final void Function()? _onOfflineSave;

  AttendanceRepository(
    this._client, 
    this._storage, 
    this._baseUrl, {
    OfflineStorageService? offlineStorage,
    void Function()? onOfflineSave,
  }) : _offlineStorage = offlineStorage,
       _onOfflineSave = onOfflineSave;

  Future<Map<String, dynamic>> checkIn(String imagePath, {String? forceType, bool isOffline = false, String? orgId, String? userId, String? timestamp}) async {
    if (isOffline && _offlineStorage != null) {
      try {
        await _offlineStorage!.saveScan(imagePath, forceType, orgId: orgId, userId: userId);
        _onOfflineSave?.call();
        return {
          'success': true,
          'message': 'Scan saved locally (Offline)',
          'offline': true,
        };
      } catch (e) {
        return {
          'success': false,
          'message': e.toString().contains('full') ? 'Storage full. Scan could not be saved.' : 'Could not save scan locally: $e',
          'error': e.toString(),
        };
      }
    }

    final token = await _storage.read(key: 'jwt_token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$_baseUrl/attendance/check-in');
    final request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $token';

    if (forceType != null) {
      request.fields['force_type'] = forceType;
    }

    if (timestamp != null) {
      request.fields['timestamp'] = timestamp;
    }
          final extension = imagePath.split('.').last.toLowerCase();
final type = (extension == 'png') ? 'png' : 'jpeg';

request.files.add(
  await http.MultipartFile.fromPath(
    'file', 
    imagePath,
    contentType: MediaType('image', type),
  ),

);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? data['detail'] ?? 'Check-in failed',
        'error': data['error']
      };
    }
  }
}

final attendanceRepositoryProvider = Provider((ref) {
  final client = ref.read(httpClientProvider);
  final storage = ref.read(secureStorageProvider);
  final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';
  final offlineStorage = ref.read(offlineStorageServiceProvider);
  
  return AttendanceRepository(
    client, 
    storage, 
    baseUrl, 
    offlineStorage: offlineStorage,
    onOfflineSave: () {
      ref.read(pendingScansCountProvider.notifier).refresh();
    },
  );
});
