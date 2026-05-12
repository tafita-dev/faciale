import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_state.dart';
import 'attendance_log_model.dart';
import 'analytics_model.dart';
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

  Future<void> fetchAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Mocking the GET /api/v1/reports/analytics call
      await Future.delayed(const Duration(milliseconds: 500));

      final mockAnalytics = AnalyticsData(
        avgPunctuality: 92.5,
        peakArrivalTime: "08:30",
        totalHoursWorked: 1240.5,
        dailyTrends: [
          DailyTrend(date: "2023-10-01", count: 45),
          DailyTrend(date: "2023-10-02", count: 52),
          DailyTrend(date: "2023-10-03", count: 48),
          DailyTrend(date: "2023-10-04", count: 55),
          DailyTrend(date: "2023-10-05", count: 50),
          DailyTrend(date: "2023-10-06", count: 42),
          DailyTrend(date: "2023-10-07", count: 10),
        ],
        statusBreakdown: StatusBreakdown(
          present: 350,
          late: 45,
          absent: 25,
        ),
      );

      state = state.copyWith(isLoading: false, analyticsData: mockAnalytics);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch analytics data',
      );
    }
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
