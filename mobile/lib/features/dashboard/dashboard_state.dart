class DashboardState {
  final int presentToday;
  final int totalEmployees;
  final int lateAbsent;
  final int totalOrganizations;
  final int totalUsers;
  final String systemHealth;
  final List<CheckInEntry> recentCheckIns;
  final bool isLoading;

  DashboardState({
    required this.presentToday,
    required this.totalEmployees,
    required this.lateAbsent,
    required this.totalOrganizations,
    required this.totalUsers,
    required this.systemHealth,
    required this.recentCheckIns,
    this.isLoading = false,
  });

  DashboardState copyWith({
    int? presentToday,
    int? totalEmployees,
    int? lateAbsent,
    int? totalOrganizations,
    int? totalUsers,
    String? systemHealth,
    List<CheckInEntry>? recentCheckIns,
    bool? isLoading,
  }) {
    return DashboardState(
      presentToday: presentToday ?? this.presentToday,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      lateAbsent: lateAbsent ?? this.lateAbsent,
      totalOrganizations: totalOrganizations ?? this.totalOrganizations,
      totalUsers: totalUsers ?? this.totalUsers,
      systemHealth: systemHealth ?? this.systemHealth,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CheckInEntry {
  final String employeeName;
  final String timestamp;

  CheckInEntry({
    required this.employeeName,
    required this.timestamp,
  });
}
