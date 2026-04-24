import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExportService {
  final String _baseUrl = 'http://192.168.0.20:4000/api/v1'; // Should be in a config
  final _storage = const FlutterSecureStorage();

  Future<void> exportAttendanceLogs() async {
    final token = await _storage.read(key: 'jwt_token');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/export?format=csv'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/attendance_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Attendance Logs Export');
    } else {
      print('Export failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to export logs: ${response.statusCode}');
    }
  }
}
