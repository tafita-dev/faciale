import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_state.dart';
import 'attendance_log_model.dart';
import 'export_service.dart';

final exportServiceProvider = Provider((ref) => ExportService());

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(() {
  return ReportsNotifier();
});

class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    return ReportsState();
  }

  Future<void> fetchLogs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Mocking the GET /api/v1/reports/logs call
      await Future.delayed(const Duration(milliseconds: 500));

      final mockLogs = [
        AttendanceLog(
          id: '1',
          employeeId: 'emp1',
          employeeName: 'John Doe',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          status: 'Present',
        ),
        AttendanceLog(
          id: '2',
          employeeId: 'emp2',
          employeeName: 'Jane Smith',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          status: 'Late',
        ),
        AttendanceLog(
          id: '3',
          employeeId: 'emp3',
          employeeName: 'Bob Johnson',
          timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          status: 'Absent',
        ),
      ];

      state = state.copyWith(isLoading: false, logs: mockLogs);
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
