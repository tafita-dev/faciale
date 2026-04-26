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
    );
  }
}

class CheckInEntry {
  final String employeeName;
  final String timestamp;
  final String status;

  CheckInEntry({
    required this.employeeName,
    required this.timestamp,
    required this.status,
  });
}
