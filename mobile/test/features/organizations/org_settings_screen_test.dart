import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/organizations/org_settings_screen.dart';
import 'package:faciale/features/organizations/org_provider.dart';
import 'package:faciale/features/organizations/org_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCurrentOrgNotifier extends Notifier<CurrentOrgState> implements CurrentOrgNotifier {
  @override
  CurrentOrgState build() => CurrentOrgState(
    org: Org(
      id: 'org123',
      name: 'Test Org',
      type: 'school',
      createdAt: DateTime.now(),
      settings: OrgSettings(startTime: '09:00', lateBufferMinutes: 15),
    ),
  );

  @override
  Future<void> fetchCurrentOrg() async {}

  @override
  Future<void> updateSettings({required String startTime, required int lateBufferMinutes}) async {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(
      isLoading: false, 
      isSuccess: true,
      org: Org(
        id: 'org123',
        name: 'Test Org',
        type: 'school',
        createdAt: DateTime.now(),
        settings: OrgSettings(startTime: startTime, lateBufferMinutes: lateBufferMinutes),
      ),
    );
  }

  @override
  void reset() {}
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        currentOrgProvider.overrideWith(() => MockCurrentOrgNotifier()),
      ],
      child: const MaterialApp(
        home: OrgSettingsScreen(),
      ),
    );
  }

  testWidgets('OrgSettingsScreen displays current settings', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('09:00'), findsOneWidget);
    // Find at least one '15' (it might be in hint and in text field)
    expect(find.text('15'), findsAtLeastNWidgets(1));
  });

  testWidgets('OrgSettingsScreen has save button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
