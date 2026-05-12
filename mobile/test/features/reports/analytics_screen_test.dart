import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/reports/analytics_screen.dart';
import 'package:faciale/features/reports/reports_provider.dart';
import 'package:faciale/features/reports/reports_state.dart';
import 'package:faciale/features/reports/analytics_model.dart';

void main() {
  testWidgets('AnalyticsScreen displays metric cards and charts', (WidgetTester tester) async {
    final mockAnalytics = AnalyticsData(
      avgPunctuality: 92.5,
      peakArrivalTime: "08:30",
      totalHoursWorked: 1240.5,
      dailyTrends: [
        DailyTrend(date: "2023-10-01", count: 45),
      ],
      statusBreakdown: StatusBreakdown(
        present: 350,
        late: 45,
        absent: 25,
      ),
    );

    final mockNotifier = ManualMockReportsNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsProvider.overrideWith(() => mockNotifier),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    // Initial state check - should show loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Provide loaded state
    mockNotifier.updateState(ReportsState(
      isLoading: false,
      analyticsData: mockAnalytics,
    ));

    await tester.pumpAndSettle();

    // Verify Metric Cards
    expect(find.text('92.5%'), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);
    expect(find.text('1240.5'), findsOneWidget);

    // Verify Titles
    expect(find.text('Average Punctuality'), findsOneWidget);
    expect(find.text('Peak Arrival Time'), findsOneWidget);
    expect(find.text('Total Hours'), findsOneWidget);
    
    // Verify Charts presence (simple check)
    expect(find.text('Daily Trends'), findsOneWidget);
    expect(find.text('Status Breakdown'), findsOneWidget);
  });
}

class ManualMockReportsNotifier extends ReportsNotifier {
  @override
  ReportsState build() => ReportsState(isLoading: true);

  @override
  Future<void> fetchAnalytics() async {
    // We handle state manually in the test
  }

  void updateState(ReportsState newState) {
    state = newState;
  }
}
