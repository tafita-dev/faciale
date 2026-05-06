import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_provider.dart';
import 'package:http_parser/http_parser.dart'; 

class AttendanceRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  AttendanceRepository(this._client, this._storage, this._baseUrl);

  Future<Map<String, dynamic>> checkIn(String imagePath, {String? forceType}) async {
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
          final extension = imagePath.split('.').last.toLowerCase();
final type = (extension == 'png') ? 'png' : 'jpeg';

request.files.add(
  await http.MultipartFile.fromPath(
    'file', 
    imagePath,
    contentType: MediaType('image', type),
  ),

);

    final streamedResponse = await request.send();
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
  return AttendanceRepository(client, storage, baseUrl);
});
