import 'attendance_log_model.dart';
import 'analytics_model.dart';

class ReportsState {
  final bool isLoading;
  final bool isExporting;
  final List<AttendanceLog> logs;
  final AnalyticsData? analyticsData;
  final String? error;

  ReportsState({
    this.isLoading = false,
    this.isExporting = false,
    this.logs = const [],
    this.analyticsData,
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    List<AttendanceLog>? logs,
    AnalyticsData? analyticsData,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      logs: logs ?? this.logs,
      analyticsData: analyticsData ?? this.analyticsData,
      error: error ?? this.error,
    );
  }
}
