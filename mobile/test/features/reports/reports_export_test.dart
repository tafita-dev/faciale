import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/reports/reports_screen.dart';
import 'package:faciale/features/reports/reports_provider.dart';
import 'package:faciale/features/reports/export_service.dart';
import 'package:mockito/mockito.dart';

class MockExportService extends Mock implements ExportService {
  @override
  Future<void> exportAttendanceLogs() => super.noSuchMethod(
        Invocation.method(#exportAttendanceLogs, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

void main() {
  testWidgets('ReportsScreen shows export button and calls exportLogs', (tester) async {
    final mockExportService = MockExportService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportServiceProvider.overrideWithValue(mockExportService),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );

    // Initial load timer
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Initial state
    final exportButton = find.byTooltip('Export CSV');
    expect(exportButton, findsOneWidget);

    // Tap export
    await tester.tap(exportButton);
    await tester.pump();

    // Verify service called
    verify(mockExportService.exportAttendanceLogs()).called(1);
  });
}
