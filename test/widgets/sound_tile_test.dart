import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/sound.dart';
import 'package:stillflow/widgets/sound_tile.dart';

void main() {
  group('SoundTile', () {
    const testSound = Sound(
      id: 'test',
      name: 'Test Sound',
      assetPath: 'assets/test.mp3',
      description: 'A test sound for testing',
    );

    testWidgets('should display sound name and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Sound'), findsOneWidget);
      expect(find.text('A test sound for testing'), findsOneWidget);
    });

    testWidgets('should show play icon when not playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('should show pause icon when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('should show playing indicator when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the indicator dot (small circular container)
      final indicatorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      expect(indicatorFinder, findsWidgets);
    });

    testWidgets('should not show playing indicator when not playing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(
              sound: testSound,
              isPlaying: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // The circular indicator should not be visible
      final indicatorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 8 &&
            widget.constraints?.maxHeight == 8,
      );

      expect(indicatorFinder, findsNothing);
    });
  });
}
