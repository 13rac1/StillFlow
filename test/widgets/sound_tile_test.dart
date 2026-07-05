import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/mix_settings.dart';
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
            body: SoundTile(sound: testSound, isPlaying: false, onTap: () {}),
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
            body: SoundTile(sound: testSound, isPlaying: false, onTap: () {}),
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
            body: SoundTile(sound: testSound, isPlaying: true, onTap: () {}),
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
            body: SoundTile(sound: testSound, isPlaying: true, onTap: () {}),
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

    testWidgets('should not show playing indicator when not playing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoundTile(sound: testSound, isPlaying: false, onTap: () {}),
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

  group('SoundTile layer controls', () {
    const environment = EnvironmentSound(
      id: 'env',
      name: 'Environment',
      assetPath: 'assets/env.ogg',
      description: 'An environment sound',
      layers: [
        SoundLayer(
          id: 'env_wind',
          name: 'Wind',
          assetPaths: ['assets/wind.ogg'],
          layerType: LayerType.continuous,
        ),
        SoundLayer(
          id: 'env_thunder',
          name: 'Thunder',
          assetPaths: ['assets/thunder.ogg'],
          layerType: LayerType.random,
          minIntervalSeconds: 30,
          maxIntervalSeconds: 120,
        ),
      ],
    );

    Widget buildTile({
      bool isPlaying = false,
      SoundMixSettings? mixSettings,
      Function(String, bool)? onLayerToggle,
      Function(String, double)? onLayerVolumeChanged,
      Function(String, double)? onLayerFrequencyChangeEnd,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SoundTile(
              sound: environment,
              isPlaying: isPlaying,
              onTap: () {},
              mixSettings: mixSettings,
              onLayerToggle: onLayerToggle,
              onLayerVolumeChanged: onLayerVolumeChanged,
              onLayerFrequencyChangeEnd: onLayerFrequencyChangeEnd,
            ),
          ),
        ),
      );
    }

    testWidgets('is expandable while NOT playing', (tester) async {
      await tester.pumpWidget(buildTile(isPlaying: false));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('Sound Layers'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('shows friendly layer type labels', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('Ambience'), findsOneWidget);
      expect(find.text('Occasional'), findsOneWidget);
      expect(find.text('Continuous'), findsNothing);
      expect(find.text('Random'), findsNothing);
    });

    testWidgets('shows a volume slider per layer and a frequency slider '
        'only for random layers', (tester) async {
      await tester.pumpWidget(
        buildTile(
          mixSettings: const SoundMixSettings(
            layers: {
              'env_wind': LayerSettings(enabled: true),
              'env_thunder': LayerSettings(enabled: true),
            },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // 2 volume sliders + 1 frequency slider
      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.text('Rare'), findsOneWidget);
      expect(find.text('Often'), findsOneWidget);
    });

    testWidgets('disables sliders when a layer is off but keeps values '
        'visible', (tester) async {
      await tester.pumpWidget(
        buildTile(
          mixSettings: const SoundMixSettings(
            layers: {
              'env_wind': LayerSettings(enabled: false, volume: 0.3),
              'env_thunder': LayerSettings(enabled: true),
            },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      final sliders = tester
          .widgetList<Slider>(find.byType(Slider))
          .toList();
      final disabled = sliders.where((s) => s.onChanged == null).toList();
      expect(disabled, hasLength(1));
      expect(disabled.first.value, 0.3);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('fires toggle and volume callbacks', (tester) async {
      String? toggledId;
      bool? toggledValue;
      String? volumeId;
      double? volumeValue;

      await tester.pumpWidget(
        buildTile(
          mixSettings: const SoundMixSettings(
            layers: {
              'env_wind': LayerSettings(enabled: true),
              'env_thunder': LayerSettings(enabled: false),
            },
          ),
          onLayerToggle: (id, enabled) {
            toggledId = id;
            toggledValue = enabled;
          },
          onLayerVolumeChanged: (id, volume) {
            volumeId = id;
            volumeValue = volume;
          },
        ),
      );
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).last);
      expect(toggledId, 'env_thunder');
      expect(toggledValue, true);

      // Drag the wind volume slider to its far left (volume 0)
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(-500, 0));
      expect(volumeId, 'env_wind');
      expect(volumeValue, 0.0);
    });
  });
}
