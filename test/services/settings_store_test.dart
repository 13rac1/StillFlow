import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillflow/models/mix_settings.dart';
import 'package:stillflow/models/sound.dart';
import 'package:stillflow/services/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsStore', () {
    test('empty prefs yield authored defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SettingsStore();
      await store.load();

      expect(store.lastSoundId, isNull);
      expect(store.equalizer, const EqualizerSettings());
      final mix = store.mixFor(SoundLibrary.rain);
      expect(mix.layers.length, SoundLibrary.rain.layers.length);
      expect(mix.enabledLayerIds, isEmpty);
      store.dispose();
    });

    test('updates round-trip through flush and reload', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SettingsStore();
      await store.load();

      store.recordLastSound('rain');
      store.updateLayer(
        'rain',
        'rain_thunder',
        const LayerSettings(enabled: true, volume: 0.6, frequency: 0.1),
      );
      store.updateEqualizer(
        const EqualizerSettings(enabled: true, frequency: 800, resonance: 0.7),
      );
      await store.flush();
      store.dispose();

      final reloaded = SettingsStore();
      await reloaded.load();
      expect(reloaded.lastSoundId, 'rain');
      expect(
        reloaded.mixFor(SoundLibrary.rain).layers['rain_thunder'],
        const LayerSettings(enabled: true, volume: 0.6, frequency: 0.1),
      );
      expect(reloaded.equalizer.enabled, true);
      expect(reloaded.equalizer.frequency, 800);
      reloaded.dispose();
    });

    test('debounces rapid updates into one coherent write', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SettingsStore();
      await store.load();

      // Rapid slider-drag style updates: nothing on disk until the debounce
      // elapses, then the latest value wins.
      for (var v = 0.0; v <= 1.0; v += 0.1) {
        store.updateLayer(
          'rain',
          'rain_wind',
          LayerSettings(enabled: true, volume: v),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsStore.prefsKey), isNull);

      await Future<void>.delayed(
        const Duration(milliseconds: 700),
      );
      final raw = prefs.getString(SettingsStore.prefsKey);
      expect(raw, isNotNull);
      final volume = ((jsonDecode(raw!) as Map<String, dynamic>)['sounds']
              as Map<String, dynamic>)['rain']['layers']['rain_wind']['volume']
          as num;
      expect(volume, closeTo(1.0, 1e-9));
      store.dispose();
    });

    test('corrupt JSON falls back to defaults without throwing', () async {
      SharedPreferences.setMockInitialValues({
        SettingsStore.prefsKey: '{not valid json!!',
      });
      final store = SettingsStore();
      await store.load();
      expect(store.lastSoundId, isNull);
      expect(store.mixFor(SoundLibrary.rain).enabledLayerIds, isEmpty);
      store.dispose();
    });

    test('mixFor merges stored partial settings over defaults and drops '
        'unknown layers', () async {
      SharedPreferences.setMockInitialValues({
        SettingsStore.prefsKey: jsonEncode({
          'version': 1,
          'sounds': {
            'rain': {
              'layers': {
                'rain_wind': {'enabled': true, 'volume': 0.3},
                'removed_layer': {'enabled': true},
              },
            },
          },
        }),
      });
      final store = SettingsStore();
      await store.load();

      final mix = store.mixFor(SoundLibrary.rain);
      expect(mix.layers['rain_wind'],
          const LayerSettings(enabled: true, volume: 0.3));
      // Untouched layers keep authored defaults; unknown ids are dropped.
      expect(mix.layers['rain_thunder'], const LayerSettings());
      expect(mix.layers.containsKey('removed_layer'), false);
      store.dispose();
    });
  });
}
