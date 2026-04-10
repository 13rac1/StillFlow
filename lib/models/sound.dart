/// Layer type for environmental sounds
enum LayerType {
  /// Continuously looping layer (e.g., crickets, wind)
  continuous,

  /// Random one-shot events (e.g., thunder, bird chirps)
  random,
}

/// Represents a single audio layer within an environment
class SoundLayer {
  final String id;
  final String name;

  /// Audio file paths. Continuous layers use one file; random layers can have
  /// multiple variants that are selected randomly each time.
  final List<String> assetPaths;

  final LayerType layerType;

  /// Minimum and maximum volume (0.0 to 1.0)
  final double minVolume;
  final double maxVolume;

  /// Minimum and maximum stereo pan position (-1.0 left to 1.0 right)
  final double minPan;
  final double maxPan;

  /// For random layers: minimum and maximum interval in seconds
  final int? minIntervalSeconds;
  final int? maxIntervalSeconds;

  /// Whether this layer is enabled by default
  final bool enabledByDefault;

  const SoundLayer({
    required this.id,
    required this.name,
    required this.assetPaths,
    required this.layerType,
    this.minVolume = 0.5,
    this.maxVolume = 1.0,
    this.minPan = -1.0,
    this.maxPan = 1.0,
    this.minIntervalSeconds,
    this.maxIntervalSeconds,
    this.enabledByDefault = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundLayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SoundLayer{id: $id, name: $name, type: $layerType}';
}

/// Represents an ambient sound available for playback
class Sound {
  final String id;
  final String name;
  final String assetPath;
  final String description;

  const Sound({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sound && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Sound{id: $id, name: $name}';
}

/// Environment sound with base loop and optional layers
class EnvironmentSound extends Sound {
  /// Available layers for this environment
  final List<SoundLayer> layers;

  const EnvironmentSound({
    required super.id,
    required super.name,
    required super.assetPath,
    required super.description,
    this.layers = const [],
  });

  /// Get all layers that are enabled by default
  List<SoundLayer> get defaultEnabledLayers =>
      layers.where((layer) => layer.enabledByDefault).toList();

  /// Get layer by ID
  SoundLayer? getLayerById(String layerId) {
    try {
      return layers.firstWhere((layer) => layer.id == layerId);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'EnvironmentSound{id: $id, name: $name, layers: ${layers.length}}';
}

/// Built-in sound library for MVP
class SoundLibrary {
  static const EnvironmentSound rain = EnvironmentSound(
    id: 'rain',
    name: 'Rain',
    assetPath: 'assets/audio/rain-sounds-ambience-351115.ogg',
    description: 'Gentle rain ambience',
    layers: [
      SoundLayer(
        id: 'rain_thunder',
        name: 'Thunder',
        assetPaths: [
          'assets/audio/rain/layers/thunder-strike-heavy.ogg',
          'assets/audio/rain/layers/thunder-rumble-long.ogg',
          'assets/audio/rain/layers/thunder-rolling-full.ogg',
          'assets/audio/rain/layers/thunder-rolling-short.ogg',
          'assets/audio/rain/layers/thunder-distant-rumble.ogg',
          'assets/audio/rain/layers/thunder-distant-boom.ogg',
        ],
        layerType: LayerType.random,
        minVolume: 0.6,
        maxVolume: 1.0,
        minIntervalSeconds: 30,
        maxIntervalSeconds: 120,
      ),
      SoundLayer(
        id: 'rain_crickets',
        name: 'Crickets',
        assetPaths: ['assets/audio/rain/layers/crickets-loop.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.4,
        maxVolume: 0.7,
        minPan: -0.3,
        maxPan: 0.3,
      ),
      SoundLayer(
        id: 'rain_wind',
        name: 'Wind',
        assetPaths: ['assets/audio/rain/layers/wind-countryside.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.4,
        maxVolume: 0.7,
        minPan: -0.5,
        maxPan: 0.5,
      ),
    ],
  );

  static const EnvironmentSound flowingWater = EnvironmentSound(
    id: 'flowing_water',
    name: 'Flowing Water',
    assetPath: 'assets/audio/flowing-water-loop-1-183953.ogg',
    description: 'Peaceful flowing water',
    layers: [
      SoundLayer(
        id: 'water_birds',
        name: 'Birds',
        assetPaths: [
          'assets/audio/water/layers/bird-chirps-1.ogg',
          'assets/audio/water/layers/bird-chirps-2.ogg',
          'assets/audio/water/layers/bird-chirps-3.ogg',
          'assets/audio/water/layers/bird-chirps-4.ogg',
          'assets/audio/water/layers/bird-song-1.ogg',
          'assets/audio/water/layers/bird-robin-1.ogg',
        ],
        layerType: LayerType.random,
        minVolume: 0.6,
        maxVolume: 1.0,
        minIntervalSeconds: 15,
        maxIntervalSeconds: 60,
      ),
      SoundLayer(
        id: 'water_frogs',
        name: 'Frogs',
        assetPaths: ['assets/audio/water/layers/frog-croaking.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.5,
        maxVolume: 0.8,
        minPan: -0.4,
        maxPan: 0.4,
      ),
      SoundLayer(
        id: 'water_breeze_gentle',
        name: 'Breeze (Gentle)',
        assetPaths: ['assets/audio/water/layers/breeze-gentle.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.3,
        maxVolume: 0.6,
        minPan: -0.3,
        maxPan: 0.3,
      ),
      SoundLayer(
        id: 'water_breeze_leaves',
        name: 'Breeze (Leaves)',
        assetPaths: ['assets/audio/water/layers/breeze-leaves.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.3,
        maxVolume: 0.6,
        minPan: -0.3,
        maxPan: 0.3,
      ),
      SoundLayer(
        id: 'water_breeze_trees',
        name: 'Breeze (Trees)',
        assetPaths: ['assets/audio/water/layers/breeze-soft-trees.ogg'],
        layerType: LayerType.continuous,
        minVolume: 0.3,
        maxVolume: 0.6,
        minPan: -0.3,
        maxPan: 0.3,
      ),
    ],
  );

  /// All available sounds for MVP
  static const List<Sound> all = [rain, flowingWater];

  /// Get a sound by ID
  static Sound? getById(String id) {
    try {
      return all.firstWhere((sound) => sound.id == id);
    } catch (_) {
      return null;
    }
  }
}
