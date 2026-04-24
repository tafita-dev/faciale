import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/reports/reports_screen.dart';
import 'package:faciale/features/reports/reports_provider.dart';
import 'package:faciale/features/reports/reports_state.dart';
import 'package:faciale/features/reports/attendance_log_model.dart';

class MockReportsNotifier extends ReportsNotifier {
  final ReportsState _mockState;
  MockReportsNotifier(this._mockState);

  @override
  ReportsState build() => _mockState;

  @override
  Future<void> fetchLogs() async {}
}

void main() {
  testWidgets('ReportsScreen shows loading indicator', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsProvider.overrideWith(() => MockReportsNotifier(ReportsState(isLoading: true))),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ReportsScreen shows list of logs', (tester) async {
    final logs = [
      AttendanceLog(id: '1', employeeId: 'e1', employeeName: 'Alice', timestamp: '2023-01-01', status: 'Present'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsProvider.overrideWith(() => MockReportsNotifier(ReportsState(logs: logs))),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
  });

  testWidgets('ReportsScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsProvider.overrideWith(() => MockReportsNotifier(ReportsState(logs: []))),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    expect(find.text('No attendance logs found.'), findsOneWidget);
  });
}
