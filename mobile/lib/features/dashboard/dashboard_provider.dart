import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_provider.dart';
import 'dashboard_state.dart';

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends Notifier<DashboardState> {
  String get _baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';

  @override
  DashboardState build() {
    // Initial load
    Future.microtask(() => refresh());
    return DashboardState();
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    if (authState.token == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final client = ref.read(httpClientProvider);
      final role = authState.role;

      if (role == 'superadmin') {
        await _fetchSuperAdminStats(client, authState.token!);
      } else {
        await _fetchOrgStats(client, authState.token!);
      }
      
      await _fetchRecentLogs(client, authState.token!);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchSuperAdminStats(dynamic client, String token) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/reports/system-stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      state = state.copyWith(
        totalOrganizations: data['total_organizations'] ?? 0,
        totalAdmins: data['total_admins'] ?? 0,
        totalUsers: data['total_users'] ?? 0,
        totalEmployees: data['total_employees'] ?? 0,
      );
    }
  }

  Future<void> _fetchOrgStats(dynamic client, String token) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/reports/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      state = state.copyWith(
        presentToday: data['present'] ?? 0,
        lateAbsent: data['absent'] ?? 0,
        totalEmployees: data['total_employees'] ?? 0,
        totalUsers: data['total_users'] ?? 0,
      );
    }
  }

  Future<void> _fetchRecentLogs(dynamic client, String token) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/reports/logs?size=10'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body)['data']['items'];
      final logs = items.map((item) {
        return CheckInEntry(
          employeeName: item['employee_name'] ?? 'Unknown',
          timestamp: _formatTimestamp(item['timestamp']),
          status: item['status'] ?? 'unknown',
        );
      }).toList();
      state = state.copyWith(recentCheckIns: logs);
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return 'N/A';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}
