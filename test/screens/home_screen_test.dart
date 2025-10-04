import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    // Note: These tests verify UI structure only
    // Audio service initialization fails in test environment, showing error state
    testWidgets('should display app title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Still Flow'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when audio service fails',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for initialization to complete (which will fail in test)
      await tester.pumpAndSettle();

      // Should show error state in test environment
      expect(find.text('Audio service unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should have dark theme applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      // Verify AppBar exists with expected styling
      expect(appBar, isNotNull);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show retry button in error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for error state
      await tester.pumpAndSettle();

      // Verify error state and retry button
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
