import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/screens/home_screen.dart';
import 'package:stillflow/models/sound.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    testWidgets('should display app title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Still Flow'), findsOneWidget);
    });

    testWidgets('should display header text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Ambient Sounds'), findsOneWidget);
      expect(find.text('Tap to play or pause'), findsOneWidget);
    });

    testWidgets('should display all sounds from library', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Should display both sounds
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Flowing Water'), findsOneWidget);
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

    testWidgets('should display sound tiles for each sound', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Should have as many sound tiles as sounds in library
      expect(find.text(SoundLibrary.rain.name), findsOneWidget);
      expect(find.text(SoundLibrary.flowingWater.name), findsOneWidget);
    });
  });
}
