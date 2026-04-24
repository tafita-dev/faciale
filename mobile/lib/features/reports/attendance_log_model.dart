class AttendanceLog {
  final String id;
  final String employeeId;
  final String employeeName;
  final String timestamp;
  final String status;

  AttendanceLog({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
