import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/mix_settings.dart';
import 'package:stillflow/models/sound.dart';

void main() {
  group('eventIntervalMultiplier', () {
    test('endpoints and midpoint', () {
      expect(eventIntervalMultiplier(0.0), closeTo(8.0, 1e-9));
      expect(eventIntervalMultiplier(0.5), closeTo(1.0, 1e-9));
      expect(eventIntervalMultiplier(1.0), closeTo(0.25, 1e-9));
    });

    test('is monotonically decreasing', () {
      var previous = eventIntervalMultiplier(0.0);
      for (var f = 0.05; f <= 1.0; f += 0.05) {
        final current = eventIntervalMultiplier(f);
        expect(current, lessThan(previous), reason: 'not decreasing at f=$f');
        previous = current;
      }
    });

    test('clamps out-of-range input', () {
      expect(eventIntervalMultiplier(-1.0), eventIntervalMultiplier(0.0));
      expect(eventIntervalMultiplier(2.0), eventIntervalMultiplier(1.0));
    });
  });

  group('LayerSettings', () {
    test('defaults reproduce authored behavior', () {
      const settings = LayerSettings();
      expect(settings.enabled, false);
      expect(settings.volume, 1.0);
      expect(settings.frequency, 0.5);
    });

    test('JSON round trip', () {
      const settings = LayerSettings(enabled: true, volume: 0.4, frequency: 0.2);
      final restored = LayerSettings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
      );
      expect(restored, settings);
    });

    test('tolerates missing and malformed fields', () {
      expect(LayerSettings.fromJson(const {}), const LayerSettings());
      final restored = LayerSettings.fromJson(const {
        'enabled': 'yes',
        'volume': 7,
        'frequency': null,
        'unknown_future_field': 42,
      });
      expect(restored.enabled, false);
      expect(restored.volume, 1.0); // 7 clamped into [0, 1]
      expect(restored.frequency, 0.5);
    });
  });

  group('SoundMixSettings', () {
    test('defaultsFor covers every layer with authored enabled state', () {
      final defaults = SoundMixSettings.defaultsFor(SoundLibrary.rain);
      expect(
        defaults.layers.keys,
        containsAll(['rain_thunder', 'rain_crickets', 'rain_wind']),
      );
      // No rain layer is enabledByDefault today.
      expect(defaults.enabledLayerIds, isEmpty);
      for (final settings in defaults.layers.values) {
        expect(settings.volume, 1.0);
        expect(settings.frequency, 0.5);
      }
    });

    test('withLayer replaces without mutating the original', () {
      final defaults = SoundMixSettings.defaultsFor(SoundLibrary.rain);
      final updated = defaults.withLayer(
        'rain_thunder',
        const LayerSettings(enabled: true, volume: 0.5),
      );
      expect(updated.enabledLayerIds, {'rain_thunder'});
      expect(defaults.enabledLayerIds, isEmpty);
    });

    test('JSON round trip and tolerant parsing', () {
      final mix = SoundMixSettings(
        layers: const {
          'rain_thunder': LayerSettings(enabled: true, frequency: 0.1),
        },
      );
      final restored = SoundMixSettings.fromJson(
        jsonDecode(jsonEncode(mix.toJson())) as Map<String, dynamic>,
      );
      expect(restored.layers['rain_thunder'], mix.layers['rain_thunder']);

      expect(SoundMixSettings.fromJson(const {}).layers, isEmpty);
      expect(
        SoundMixSettings.fromJson(const {'layers': 'garbage'}).layers,
        isEmpty,
      );
    });
  });

  group('EqualizerSettings', () {
    test('defaults match handler initial state', () {
      const eq = EqualizerSettings();
      expect(eq.enabled, false);
      expect(eq.frequency, 2000.0);
      expect(eq.resonance, 1.0);
    });

    test('JSON round trip clamps to slider bounds', () {
      const eq = EqualizerSettings(enabled: true, frequency: 800, resonance: 0.7);
      final restored = EqualizerSettings.fromJson(
        jsonDecode(jsonEncode(eq.toJson())) as Map<String, dynamic>,
      );
      expect(restored, eq);

      final clamped = EqualizerSettings.fromJson(const {
        'enabled': true,
        'frequency': 99999,
        'resonance': -3,
      });
      expect(clamped.frequency, 8000.0);
      expect(clamped.resonance, 0.1);
    });
  });

  group('AppSettings', () {
    test('JSON round trip', () {
      final settings = AppSettings(
        lastSoundId: 'rain',
        sounds: const {
          'rain': SoundMixSettings(
            layers: {'rain_wind': LayerSettings(enabled: true, volume: 0.3)},
          ),
        },
        equalizer: const EqualizerSettings(enabled: true, frequency: 800),
      );
      final restored = AppSettings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
      );
      expect(restored.lastSoundId, 'rain');
      expect(
        restored.sounds['rain']!.layers['rain_wind'],
        const LayerSettings(enabled: true, volume: 0.3),
      );
      expect(restored.equalizer, settings.equalizer);
    });

    test('empty or malformed JSON yields defaults', () {
      final restored = AppSettings.fromJson(const {
        'lastSoundId': 123,
        'sounds': 'garbage',
        'equalizer': [1, 2, 3],
      });
      expect(restored.lastSoundId, isNull);
      expect(restored.sounds, isEmpty);
      expect(restored.equalizer, const EqualizerSettings());
    });
  });
}
