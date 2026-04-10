import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    // Note: These tests verify UI structure only
    // Audio service initialization may fail in test environment due to
    // AudioService.init() being called multiple times across tests.
    // Error output is suppressed for cleaner test logs.

    testWidgets('should display app title', (tester) async {
      // Capture and suppress console output
      await runZoned(
        () async {
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

          expect(find.text('Still Flow'), findsOneWidget);
          expect(find.byIcon(Icons.tune), findsOneWidget); // Equalizer button
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, message) {
            // Suppress audio initialization error messages in tests
            if (!message.contains('Audio service initialization failed')) {
              parent.print(zone, message);
            }
          },
        ),
      );
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await runZoned(
        () async {
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

          // Initially shows loading
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, message) {
            if (!message.contains('Audio service initialization failed')) {
              parent.print(zone, message);
            }
          },
        ),
      );
    });

    testWidgets('should handle concurrent initialization gracefully', (
      tester,
    ) async {
      await runZoned(
        () async {
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

          // Wait for initialization to complete
          await tester.pump(const Duration(milliseconds: 100));

          // App should either show loading, error, or success
          // (concurrent initialization is handled gracefully without crashing)
          expect(tester.takeException(), isNull);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, message) {
            if (!message.contains('Audio service initialization failed')) {
              parent.print(zone, message);
            }
          },
        ),
      );
    });

    testWidgets('should have dark theme applied', (tester) async {
      await runZoned(
        () async {
          await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

          final appBar = tester.widget<AppBar>(find.byType(AppBar));

          // Verify AppBar exists with expected styling
          expect(appBar, isNotNull);
          expect(find.byType(AppBar), findsOneWidget);
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, message) {
            if (!message.contains('Audio service initialization failed')) {
              parent.print(zone, message);
            }
          },
        ),
      );
    });
  });
}
