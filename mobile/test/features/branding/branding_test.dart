import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/main.dart';
import 'package:faciale/features/auth/login_screen.dart';
import 'package:faciale/core/widgets/logo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() async {
    // Load a mock .env for tests
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
  });

  testWidgets('App title should be I-POINTEO', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FacialeApp()));
    
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'I-POINTEO');
  });

  testWidgets('LoginScreen should display the I-POINTEO Logo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byType(Logo), findsOneWidget);
    expect(find.text('I-POINTEO'), findsOneWidget);
  });
}
