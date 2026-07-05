import 'dart:math';

import 'sound.dart';

/// Interval multiplier for a random layer's event-frequency slider value
/// [f] in [0, 1] (0 = rare, 0.5 = authored cadence, 1 = often).
///
/// Piecewise log scale, asymmetric because "much rarer than authored" is the
/// product requirement (the sleep-vs-focus dial): f=0 stretches intervals 8×
/// (thunder authored at 30–120s becomes 4–16 min), f=1 compresses them 4×.
/// Both branches meet at m(0.5) = 1 so the default reproduces the authored
/// behavior exactly, and the curve is continuous and monotonic.
double eventIntervalMultiplier(double f) {
  final x = f.clamp(0.0, 1.0);
  return x <= 0.5
      ? pow(8, 1 - 2 * x).toDouble()
      : pow(4, 1 - 2 * x).toDouble();
}

double _readDouble(Object? value, double fallback, double min, double max) {
  if (value is num) return value.toDouble().clamp(min, max);
  return fallback;
}

bool _readBool(Object? value, bool fallback) {
  if (value is bool) return value;
  return fallback;
}

/// User-configured settings for one layer of an environment sound.
///
/// [volume] multiplies the layer's authored min/max volume range (1.0 = the
/// authored loudness, today's behavior). [frequency] is the rare→often event
/// slider for random layers (0.5 = authored intervals); it is stored for
/// continuous layers too but has no effect on them.
class LayerSettings {
  final bool enabled;
  final double volume;
  final double frequency;

  const LayerSettings({
    this.enabled = false,
    this.volume = 1.0,
    this.frequency = 0.5,
  });

  LayerSettings copyWith({bool? enabled, double? volume, double? frequency}) {
    return LayerSettings(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
      frequency: frequency ?? this.frequency,
    );
  }

  factory LayerSettings.fromJson(Map<String, dynamic> json) {
    return LayerSettings(
      enabled: _readBool(json['enabled'], false),
      volume: _readDouble(json['volume'], 1.0, 0.0, 1.0),
      frequency: _readDouble(json['frequency'], 0.5, 0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'volume': volume,
    'frequency': frequency,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          volume == other.volume &&
          frequency == other.frequency;

  @override
  int get hashCode => Object.hash(enabled, volume, frequency);

  @override
  String toString() =>
      'LayerSettings{enabled: $enabled, volume: $volume, frequency: $frequency}';
}

/// The desired mix for one environment sound: settings per layer id.
class SoundMixSettings {
  final Map<String, LayerSettings> layers;

  const SoundMixSettings({this.layers = const {}});

  /// The authored defaults for [sound]: every layer present, enabled per
  /// [SoundLayer.enabledByDefault], volume/frequency at their neutral values.
  factory SoundMixSettings.defaultsFor(EnvironmentSound sound) {
    return SoundMixSettings(
      layers: {
        for (final layer in sound.layers)
          layer.id: LayerSettings(enabled: layer.enabledByDefault),
      },
    );
  }

  Set<String> get enabledLayerIds => {
    for (final entry in layers.entries)
      if (entry.value.enabled) entry.key,
  };

  SoundMixSettings withLayer(String layerId, LayerSettings settings) {
    return SoundMixSettings(layers: {...layers, layerId: settings});
  }

  factory SoundMixSettings.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['layers'];
    return SoundMixSettings(
      layers: {
        if (rawLayers is Map<String, dynamic>)
          for (final entry in rawLayers.entries)
            if (entry.value is Map<String, dynamic>)
              entry.key: LayerSettings.fromJson(
                entry.value as Map<String, dynamic>,
              ),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'layers': {
      for (final entry in layers.entries) entry.key: entry.value.toJson(),
    },
  };
}

/// User-configured low-pass filter settings. Defaults match the handler's
/// initial state (disabled, 2000 Hz, resonance 1.0).
class EqualizerSettings {
  final bool enabled;
  final double frequency;
  final double resonance;

  const EqualizerSettings({
    this.enabled = false,
    this.frequency = 2000.0,
    this.resonance = 1.0,
  });

  EqualizerSettings copyWith({
    bool? enabled,
    double? frequency,
    double? resonance,
  }) {
    return EqualizerSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      resonance: resonance ?? this.resonance,
    );
  }

  factory EqualizerSettings.fromJson(Map<String, dynamic> json) {
    return EqualizerSettings(
      enabled: _readBool(json['enabled'], false),
      frequency: _readDouble(json['frequency'], 2000.0, 500.0, 8000.0),
      resonance: _readDouble(json['resonance'], 1.0, 0.1, 5.0),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'frequency': frequency,
    'resonance': resonance,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          frequency == other.frequency &&
          resonance == other.resonance;

  @override
  int get hashCode => Object.hash(enabled, frequency, resonance);
}

/// Everything StillFlow persists across launches. Parsing is tolerant:
/// unknown fields are ignored and malformed ones fall back to defaults, so a
/// settings blob from a newer or older version never crashes the app.
class AppSettings {
  static const int currentVersion = 1;

  final String? lastSoundId;
  final Map<String, SoundMixSettings> sounds;
  final EqualizerSettings equalizer;

  const AppSettings({
    this.lastSoundId,
    this.sounds = const {},
    this.equalizer = const EqualizerSettings(),
  });

  AppSettings copyWith({
    String? lastSoundId,
    Map<String, SoundMixSettings>? sounds,
    EqualizerSettings? equalizer,
  }) {
    return AppSettings(
      lastSoundId: lastSoundId ?? this.lastSoundId,
      sounds: sounds ?? this.sounds,
      equalizer: equalizer ?? this.equalizer,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawSounds = json['sounds'];
    final rawEqualizer = json['equalizer'];
    return AppSettings(
      lastSoundId: json['lastSoundId'] is String
          ? json['lastSoundId'] as String
          : null,
      sounds: {
        if (rawSounds is Map<String, dynamic>)
          for (final entry in rawSounds.entries)
            if (entry.value is Map<String, dynamic>)
              entry.key: SoundMixSettings.fromJson(
                entry.value as Map<String, dynamic>,
              ),
      },
      equalizer: rawEqualizer is Map<String, dynamic>
          ? EqualizerSettings.fromJson(rawEqualizer)
          : const EqualizerSettings(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    if (lastSoundId != null) 'lastSoundId': lastSoundId,
    'sounds': {
      for (final entry in sounds.entries) entry.key: entry.value.toJson(),
    },
    'equalizer': equalizer.toJson(),
  };
}
