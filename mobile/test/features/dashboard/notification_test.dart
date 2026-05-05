import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/dashboard/dashboard_screen.dart';
import 'package:faciale/features/dashboard/dashboard_provider.dart';
import 'package:faciale/features/dashboard/dashboard_state.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/features/auth/auth_state.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';

import 'notification_test.mocks.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockClient mockClient;
  late ProviderContainer container;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
    mockClient = MockClient();
    container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(mockClient),
        authProvider.overrideWith(() => AuthNotifierMock(AuthState(token: 'test_token', role: 'admin'))),
      ],
    );
  });

  test('DashboardNotifier detects new log and sets lastNotification', () async {
    final notifier = container.read(dashboardProvider.notifier);

    // Mock for _fetchOrgStats
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/reports/stats'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode({'data': {'present': 1, 'absent': 0, 'total_employees': 1}}), 200));

    // 1. Initial logs mock
    final initialLogsResponse = {
      'data': {
        'items': [
          {
            'id': 'log1',
            'employee_name': 'John Doe',
            'timestamp': '2024-01-01T09:00:00Z',
            'status': 'present',
          }
        ]
      }
    };

    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/reports/logs?size=10'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(initialLogsResponse), 200));

    await notifier.refresh();
    
    expect(container.read(dashboardProvider).recentCheckIns.length, 1);
    expect(container.read(dashboardProvider).lastNotification, isNull);

    // 2. New log via polling mock
    final newLogsResponse = {
      'data': {
        'items': [
          {
            'id': 'log2',
            'employee_name': 'Jane Smith',
            'timestamp': '2024-01-01T09:05:00Z',
            'status': 'late',
          },
          {
            'id': 'log1',
            'employee_name': 'John Doe',
            'timestamp': '2024-01-01T09:00:00Z',
            'status': 'present',
          }
        ]
      }
    };

    // Update mock for next call
    when(mockClient.get(Uri.parse('http://localhost:8000/api/v1/reports/logs?size=10'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(newLogsResponse), 200));

    // Manually trigger polling
    await notifier.poll();
    
    final state = container.read(dashboardProvider);
    expect(state.recentCheckIns.length, 2);
    expect(state.lastNotification, isNotNull);
    expect(state.lastNotification!.id, 'log2');
  });

  test('DashboardNotifier detects update to existing log (checkout)', () async {
    final notifier = container.read(dashboardProvider.notifier);

    // 1. Initial log mock (entry)
    final initialLogsResponse = {
      'data': {
        'items': [
          {
            'id': 'log1',
            'employee_name': 'John Doe',
            'timestamp': '2024-01-01T09:00:00Z',
            'status': 'present',
            'type': 'entry',
          }
        ]
      }
    };

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(initialLogsResponse), 200));

    await notifier.refresh();
    expect(container.read(dashboardProvider).recentCheckIns.first.type, 'entry');

    // 2. Updated log (checkout)
    final updatedLogsResponse = {
      'data': {
        'items': [
          {
            'id': 'log1',
            'employee_name': 'John Doe',
            'timestamp': '2024-01-01T17:00:00Z', // Different timestamp
            'status': 'present',
            'type': 'exit',
          }
        ]
      }
    };

    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(updatedLogsResponse), 200));

    await notifier.poll();
    
    final state = container.read(dashboardProvider);
    expect(state.lastNotification, isNotNull);
    expect(state.lastNotification!.id, 'log1');
    expect(state.lastNotification!.type, 'exit');
  });

  test('DashboardNotifier clearNotification clears lastNotification', () async {
    final notifier = container.read(dashboardProvider.notifier);
    
    // Use poll to set a notification if we have a state
    final logsResponse = {
      'data': {
        'items': [{'id': 'log1', 'employee_name': 'N', 'timestamp': '2024-01-01T09:00:00Z', 'status': 'present'}]
      }
    };
    
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(logsResponse), 200));
        
    // Set initial state via refresh
    await notifier.refresh();
    
    // New log to trigger notification
    final newLogsResponse = {
      'data': {
        'items': [
          {'id': 'log2', 'employee_name': 'N2', 'timestamp': '2024-01-01T09:01:00Z', 'status': 'present'},
          {'id': 'log1', 'employee_name': 'N', 'timestamp': '2024-01-01T09:00:00Z', 'status': 'present'}
        ]
      }
    };
    when(mockClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(jsonEncode(newLogsResponse), 200));
        
    await notifier.poll();
    
    expect(container.read(dashboardProvider).lastNotification, isNotNull);
    
    notifier.clearNotification();
    
    expect(container.read(dashboardProvider).lastNotification, isNull);
  });

  testWidgets('DashboardScreen shows SnackBar when lastNotification is set', (WidgetTester tester) async {
    final logs = [
      CheckInEntry(id: 'log1', employeeName: 'John Doe', timestamp: '09:00', status: 'present'),
    ];
    
    final initialState = DashboardState(recentCheckIns: logs);
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => AuthNotifierMock(AuthState(role: 'admin'))),
          dashboardProvider.overrideWith(() => DashboardNotifierMock(initialState)),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Get the notifier
    final element = tester.element(find.byType(DashboardScreen));
    final container = ProviderScope.containerOf(element);
    final notifier = container.read(dashboardProvider.notifier) as DashboardNotifierMock;

    // Simulate a new notification
    final newLog = CheckInEntry(id: 'log2', employeeName: 'Jane Smith', timestamp: '09:05', status: 'late');
    notifier.setNotification(newLog);
    
    await tester.pumpAndSettle(); // Trigger ref.listen and wait for SnackBar
    
    // SnackBar should be visible
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('success_checkin_notif'), findsOneWidget);
  });
}

class DashboardNotifierMock extends DashboardNotifier {
  final DashboardState initial;
  DashboardNotifierMock(this.initial);

  @override
  DashboardState build() {
    return initial;
  }

  @override
  void _startPolling() {} // Disable polling in test

  @override
  Future<void> refresh() async {}

  void setNotification(CheckInEntry log) {
    state = state.copyWith(lastNotification: log);
  }
  
  @override
  void clearNotification() {
    state = state.clearNotification();
  }
}

class AuthNotifierMock extends Notifier<AuthState> implements AuthNotifier {
  final AuthState initialState;
  AuthNotifierMock(this.initialState);

  @override
  AuthState build() => initialState;
  
  @override
  Future<void> login(String email, String password) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {}
  @override
  Future<void> requestPasswordReset(String email) async {}
  @override
  void resetStatus() {}
  @override
  Future<void> fetchProfile() async {}
}
