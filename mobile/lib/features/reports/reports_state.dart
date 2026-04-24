import 'attendance_log_model.dart';

class ReportsState {
  final bool isLoading;
  final bool isExporting;
  final List<AttendanceLog> logs;
  final String? error;

  ReportsState({
    this.isLoading = false,
    this.isExporting = false,
    this.logs = const [],
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    List<AttendanceLog>? logs,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      logs: logs ?? this.logs,
      error: error ?? this.error,
    );
  }
}
