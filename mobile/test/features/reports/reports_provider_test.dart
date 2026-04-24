import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/reports/reports_provider.dart';

void main() {
  test('ReportsNotifier starts with empty list and not loading', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(reportsProvider);
    expect(state.isLoading, false);
    expect(state.logs, isEmpty);
  });

  test('ReportsNotifier.fetchLogs sets loading then updates logs', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(reportsProvider.notifier);
    
    await notifier.fetchLogs();
    
    final state = container.read(reportsProvider);
    expect(state.isLoading, false);
    expect(state.logs, isNotEmpty);
  });
}
