import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mix_settings.dart';
import '../models/sound.dart';

/// Persists the user's desired mix and equalizer settings across launches.
///
/// This is the single source of truth for the *desired* state (including
/// sounds that aren't playing); [SoLoudAudioHandler] remains the authority
/// for what is audible and never persists anything itself.
///
/// Everything is stored as one JSON blob under [prefsKey] so a write is
/// atomic and versioning is a key bump. Setters mutate in memory immediately
/// and debounce the disk write (slider drags fire dozens of updates per
/// second); call [flush] on app lifecycle pauses so a killed process loses at
/// most the debounce window.
class SettingsStore {
  static const String prefsKey = 'stillflow.settings.v1';
  static const Duration _saveDebounce = Duration(milliseconds: 500);

  AppSettings _settings = const AppSettings();
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  /// Load persisted settings. Any failure (missing key, corrupt JSON, prefs
  /// backend unavailable) falls back to defaults — settings must never crash
  /// the app.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(prefsKey);
      if (raw != null) {
        _settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('⚠️  Failed to load settings, using defaults: $e');
      _settings = const AppSettings();
    }
  }

  /// The id of the last sound the user played, if any.
  String? get lastSoundId => _settings.lastSoundId;

  void recordLastSound(String soundId) {
    _settings = _settings.copyWith(lastSoundId: soundId);
    _scheduleSave();
  }

  /// The desired mix for [sound]: authored defaults overlaid with whatever
  /// the user has stored. Every layer of [sound] is present in the result;
  /// stored settings for layers that no longer exist are ignored.
  SoundMixSettings mixFor(EnvironmentSound sound) {
    final defaults = SoundMixSettings.defaultsFor(sound);
    final stored = _settings.sounds[sound.id];
    if (stored == null) return defaults;
    return SoundMixSettings(
      layers: {
        for (final entry in defaults.layers.entries)
          entry.key: stored.layers[entry.key] ?? entry.value,
      },
    );
  }

  void updateLayer(String soundId, String layerId, LayerSettings settings) {
    final mix = _settings.sounds[soundId] ?? const SoundMixSettings();
    _settings = _settings.copyWith(
      sounds: {..._settings.sounds, soundId: mix.withLayer(layerId, settings)},
    );
    _scheduleSave();
  }

  EqualizerSettings get equalizer => _settings.equalizer;

  void updateEqualizer(EqualizerSettings settings) {
    _settings = _settings.copyWith(equalizer: settings);
    _scheduleSave();
  }

  /// Write any pending changes immediately (app going to background, dispose).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await _write();
  }

  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      _saveTimer = null;
      unawaited(_write());
    });
  }

  Future<void> _write() async {
    final prefs = _prefs;
    if (prefs == null) return; // load() never ran or prefs unavailable
    try {
      await prefs.setString(prefsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('⚠️  Failed to save settings: $e');
    }
  }
}
