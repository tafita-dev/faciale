class DashboardState {
  final int presentToday;
  final int totalEmployees;
  final int lateAbsent;
  final int totalOrganizations;
  final int totalUsers;
  final int totalAdmins;
  final String systemHealth;
  final List<CheckInEntry> recentCheckIns;
  final bool isLoading;
  final String? error;
  final CheckInEntry? lastNotification;

  DashboardState({
    this.presentToday = 0,
    this.totalEmployees = 0,
    this.lateAbsent = 0,
    this.totalOrganizations = 0,
    this.totalUsers = 0,
    this.totalAdmins = 0,
    this.systemHealth = 'Healthy',
    this.recentCheckIns = const [],
    this.isLoading = false,
    this.error,
    this.lastNotification,
  });

  DashboardState copyWith({
    int? presentToday,
    int? totalEmployees,
    int? lateAbsent,
    int? totalOrganizations,
    int? totalUsers,
    int? totalAdmins,
    String? systemHealth,
    List<CheckInEntry>? recentCheckIns,
    bool? isLoading,
    String? error,
    CheckInEntry? lastNotification,
  }) {
    return DashboardState(
      presentToday: presentToday ?? this.presentToday,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      lateAbsent: lateAbsent ?? this.lateAbsent,
      totalOrganizations: totalOrganizations ?? this.totalOrganizations,
      totalUsers: totalUsers ?? this.totalUsers,
      totalAdmins: totalAdmins ?? this.totalAdmins,
      systemHealth: systemHealth ?? this.systemHealth,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastNotification: lastNotification ?? this.lastNotification,
    );
  }

  DashboardState clearNotification() {
    return DashboardState(
      presentToday: presentToday,
      totalEmployees: totalEmployees,
      lateAbsent: lateAbsent,
      totalOrganizations: totalOrganizations,
      totalUsers: totalUsers,
      totalAdmins: totalAdmins,
      systemHealth: systemHealth,
      recentCheckIns: recentCheckIns,
      isLoading: isLoading,
      error: error,
      lastNotification: null,
    );
  }
}

class CheckInEntry {
  final String id;
  final String employeeName;
  final String timestamp;
  final String status;
  final String? reason;
  final String type; // entry, exit, failure

  CheckInEntry({
    required this.id,
    required this.employeeName,
    required this.timestamp,
    required this.status,
    this.reason,
    this.type = 'entry',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp;

  @override
  int get hashCode => id.hashCode ^ timestamp.hashCode;
}
