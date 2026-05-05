import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';

void main() {
  testWidgets('NeumorphicButton renders and handles tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeumorphicButton(
            onPressed: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    
    await tester.tap(find.text('Tap Me'));
    expect(tapped, isTrue);
  });

  testWidgets('NeumorphicButton changes state when pressed', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeumorphicButton(
            onPressed: () {},
            child: const Text('Button'),
          ),
        ),
      ),
    );

    // Initial state (Raised)
    final containerBefore = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decorationBefore = containerBefore.decoration as BoxDecoration;
    expect(decorationBefore.boxShadow, isNotNull);
    
    // Start gesture
    final gesture = await tester.startGesture(tester.getCenter(find.text('Button')));
    await tester.pump(); // Start animation
    
    // Pressed state (Inset look usually achieved by reducing shadow or changing offset)
    final containerAfter = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final decorationAfter = containerAfter.decoration as BoxDecoration;
    
    // In our implementation we will probably reduce offset/blur to simulate inset or pressed
    expect(decorationAfter.boxShadow![0].offset, isNot(decorationBefore.boxShadow![0].offset));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
