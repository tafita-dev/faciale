import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faciale/core/widgets/responsive_layout.dart';

void main() {
  testWidgets('ResponsiveLayout selects mobile widget for narrow screens', (WidgetTester tester) async {
    const mobileWidget = Text('Mobile');
    const tabletWidget = Text('Tablet');

    // Set screen size to mobile
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveLayout(
          mobile: mobileWidget,
          tablet: tabletWidget,
        ),
      ),
    );

    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Tablet'), findsNothing);
  });

  testWidgets('ResponsiveLayout selects tablet widget for wide screens', (WidgetTester tester) async {
    const mobileWidget = Text('Mobile');
    const tabletWidget = Text('Tablet');

    // Set screen size to tablet
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveLayout(
          mobile: mobileWidget,
          tablet: tabletWidget,
        ),
      ),
    );

    expect(find.text('Tablet'), findsOneWidget);
    expect(find.text('Mobile'), findsNothing);
  });
}
