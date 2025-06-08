// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arcane/src/app.dart';
import 'package:provider/provider.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import './mock.dart'; // For Firebase mock

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App builds and shows loading or login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => GameProvider(),
        child: const MyApp(),
      ),
    );
    
    // Wait for all async operations like Firebase init and auth state to settle.
    await tester.pumpAndSettle();

    // The app should build a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Depending on the initial state of the mocked GameProvider,
    // it will either show a loading indicator, the LoginScreen, or the HomeScreen.
    // A robust test would mock the GameProvider's state.
    // A simple smoke test can check for one of the possible outcomes.
    // Let's assume the initial state leads to the LoginScreen.
    expect(find.text('ARCANE'), findsOneWidget);
    expect(find.text('Secure Login'), findsOneWidget);
  });
}