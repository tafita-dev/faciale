import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_state.dart';

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return DashboardState(
      presentToday: 42,
      totalEmployees: 150,
      lateAbsent: 8,
      totalOrganizations: 12,
      totalUsers: 1800,
      systemHealth: 'Optimal',
      recentCheckIns: [
        CheckInEntry(employeeName: 'John Doe', timestamp: '10:30 AM'),
        CheckInEntry(employeeName: 'Jane Smith', timestamp: '10:15 AM'),
        CheckInEntry(employeeName: 'Robert Brown', timestamp: '09:50 AM'),
        CheckInEntry(employeeName: 'Emily White', timestamp: '09:45 AM'),
        CheckInEntry(employeeName: 'Michael Green', timestamp: '09:30 AM'),
      ],
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    // Mocking API call
    await Future.delayed(const Duration(seconds: 1));
    // Here I would fetch the data from an API
    state = state.copyWith(isLoading: false);
  }
}
