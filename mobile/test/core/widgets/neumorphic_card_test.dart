import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faciale/core/widgets/neumorphic_card.dart';

void main() {
  testWidgets('NeumorphicCard renders child and has shadows', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeumorphicCard(
            child: Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
    
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow!.length, greaterThanOrEqualTo(2));
    expect(decoration.borderRadius, isNotNull);
  });
}
