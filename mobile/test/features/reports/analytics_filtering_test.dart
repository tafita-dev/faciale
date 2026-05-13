import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/reports/analytics_screen.dart';
import 'package:faciale/features/reports/reports_provider.dart';
import 'package:faciale/features/reports/reports_state.dart';
import 'package:faciale/features/reports/analytics_model.dart';
import 'package:faciale/features/organizations/department_provider.dart';
import 'package:mockito/mockito.dart';

class MockReportsNotifier extends ReportsNotifier {
  int fetchAnalyticsCount = 0;
  DateTime? lastStartDate;
  DateTime? lastEndDate;
  String? lastDeptId;

  @override
  ReportsState build() {
    return ReportsState(
      isLoading: false,
      analyticsData: AnalyticsData(
        avgPunctuality: 92.5,
        peakArrivalTime: "08:30",
        totalHoursWorked: 1240.5,
        dailyTrends: [],
        statusBreakdown: StatusBreakdown(present: 1, late: 0, absent: 0),
      ),
    );
  }

  @override
  Future<void> fetchAnalytics({DateTime? startDate, DateTime? endDate, String? deptId}) async {
    fetchAnalyticsCount++;
    lastStartDate = startDate;
    lastEndDate = endDate;
    lastDeptId = deptId;
  }
}

class MockDeptNotifier extends DepartmentNotifier {
  @override
  DeptState build() {
    return DeptState(
      departments: [
        Department(id: 'dept1', name: 'Engineering'),
        Department(id: 'dept2', name: 'HR'),
      ],
    );
  }

  @override
  Future<void> fetchDepartments() async {}
}

void main() {
  testWidgets('AnalyticsScreen allows filtering by date and department', (WidgetTester tester) async {
    final mockReportsNotifier = MockReportsNotifier();
    final mockDeptNotifier = MockDeptNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsProvider.overrideWith(() => mockReportsNotifier),
          departmentProvider.overrideWith(() => mockDeptNotifier),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial fetch was called (once in initState)
    expect(mockReportsNotifier.fetchAnalyticsCount, 1);

    // Look for Date Range button/picker (implementation pending)
    // For now, let's assume we have a "Filter" button or similar that opens a dialog/bottom sheet
    // Or just find by Icon
    final filterIcon = find.byIcon(Icons.filter_list);
    expect(filterIcon, findsOneWidget);

    await tester.tap(filterIcon);
    await tester.pumpAndSettle();

    // In the filter dialog/sheet, find department dropdown
    expect(find.text('Department'), findsOneWidget);
    await tester.tap(find.text('All Departments'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Verify fetchAnalytics was called with deptId
    expect(mockReportsNotifier.lastDeptId, 'dept1');
    expect(mockReportsNotifier.fetchAnalyticsCount, 2);
  });
}
