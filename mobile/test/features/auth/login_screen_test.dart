import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/main.dart';
import 'package:faciale/features/auth/login_screen.dart';
import 'package:faciale/features/auth/auth_provider.dart';
import 'package:faciale/core/widgets/neumorphic_button.dart';
import 'package:faciale/core/widgets/logo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'auth_provider_test.mocks.dart';

import 'package:faciale/features/dashboard/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockClient mockClient;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
    mockClient = MockClient();
    mockStorage = MockFlutterSecureStorage();

    // Stub storage methods
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async => {});
    when(mockStorage.read(key: anyNamed('key')))
        .thenAnswer((_) async => null);
    when(mockStorage.delete(key: anyNamed('key')))
        .thenAnswer((_) async => {});
  });

  testWidgets('Login Screen UI Elements Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byType(Logo), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(NeumorphicButton), findsOneWidget);
  });

  testWidgets('Successful Login redirect placeholder test', (WidgetTester tester) async {
    const dummyToken = "header.eyJzdWIiOiAidGVzdEB0ZXN0LmNvbSIsICJyb2xlIjogInN1cGVyYWRtaW4iLCAib3JnX2lkIjogIm9yZzEyMyJ9.signature";
    
    final completer = Completer<http.Response>();
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: const FacialeApp(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'admin@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    
    await tester.tap(find.byType(NeumorphicButton));
    await tester.pump(); // Start loading
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    completer.complete(http.Response(jsonEncode({'access_token': dummyToken}), 200));
    await tester.pumpAndSettle(); 

    // Verification: Redirect to Dashboard
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('Invalid Credentials shows snackbar', (WidgetTester tester) async {
    final completer = Completer<http.Response>();
    when(mockClient.post(any, body: anyNamed('body')))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: const FacialeApp(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    
    await tester.tap(find.byType(NeumorphicButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response(jsonEncode({'detail': 'Invalid email or password'}), 401));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
