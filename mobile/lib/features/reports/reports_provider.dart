import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'reports_state.dart';
import 'attendance_log_model.dart';
import 'analytics_model.dart';
import 'export_service.dart';
import '../auth/auth_provider.dart';

final exportServiceProvider = Provider((ref) => ExportService());

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(() {
  return ReportsNotifier();
});

class ReportsNotifier extends Notifier<ReportsState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  ReportsState build() {
    // Default to last 30 days
    final now = DateTime.now();
    return ReportsState(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }

  void setFilters({DateTime? startDate, DateTime? endDate, String? deptId}) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      deptId: deptId,
    );
  }

  Future<void> fetchAnalytics({DateTime? startDate, DateTime? endDate, String? deptId}) async {
    // Use provided filters or fallback to state
    final start = startDate ?? state.startDate;
    final end = endDate ?? state.endDate;
    final dept = deptId ?? state.deptId;

    // Update state filters if they were passed explicitly
    if (startDate != null || endDate != null || deptId != null) {
      state = state.copyWith(startDate: start, endDate: end, deptId: dept);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final queryParams = {
        'start_date': start?.toIso8601String(),
        'end_date': end?.toIso8601String(),
      };
      if (dept != null && dept != 'all') {
        queryParams['dept_id'] = dept;
      }

      final uri = Uri.parse('$_baseUrl/reports/analytics').replace(queryParameters: queryParams);
      
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analytics = AnalyticsData.fromJson(data['data'] ?? data);
        state = state.copyWith(isLoading: false, analyticsData: analytics);
      } else {
        // Fallback to mock for development/demo if backend is not ready, 
        // but since US-16-ANLY-001 is DONE, it should work.
        // Let's add a proper error handling.
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isLoading: false,
          error: data['detail'] ?? 'Failed to fetch analytics data',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch analytics data: ${e.toString()}',
      );
    }
  }

  Future<void> fetchLogs({DateTime? startDate, DateTime? endDate, String? deptId}) async {
    final start = startDate ?? state.startDate;
    final end = endDate ?? state.endDate;
    final dept = deptId ?? state.deptId;

    if (startDate != null || endDate != null || deptId != null) {
      state = state.copyWith(startDate: start, endDate: end, deptId: dept);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final authState = ref.read(authProvider);

      final queryParams = {
        'start_date': start?.toIso8601String(),
        'end_date': end?.toIso8601String(),
      };
      if (dept != null && dept != 'all') {
        queryParams['dept_id'] = dept;
      }

      final uri = Uri.parse('$_baseUrl/reports/logs').replace(queryParameters: queryParams);
      
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        final logs = items.map((item) => AttendanceLog.fromJson(item)).toList();
        state = state.copyWith(isLoading: false, logs: logs);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch attendance logs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch attendance logs',
      );
    }
  }

  Future<void> exportLogs() async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      final exportService = ref.read(exportServiceProvider);
      await exportService.exportAttendanceLogs();
      state = state.copyWith(isExporting: false);
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export logs: ${e.toString()}',
      );
    }
  }
}
