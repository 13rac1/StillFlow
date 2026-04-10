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

/// Attribution information for a source audio recording
class Attribution {
  final String title;
  final String author;
  final String url;
  final String license;

  const Attribution({
    required this.title,
    required this.author,
    required this.url,
    required this.license,
  });
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

  /// Attribution for all audio sources
  static const List<Attribution> attributions = [
    // Base loops (Pixabay)
    Attribution(
      title: 'Rain Sounds Ambience',
      author: 'DRAGON-STUDIO',
      url: 'https://pixabay.com/sound-effects/rain-sounds-ambience-351115/',
      license: 'Pixabay Content License',
    ),
    Attribution(
      title: 'Flowing Water Loop 1',
      author: 'floraphonic',
      url: 'https://pixabay.com/sound-effects/flowing-water-loop-1-183953/',
      license: 'Pixabay Content License',
    ),
    // Rain layers (Freesound)
    Attribution(
      title: 'Heavy Thunder Strike No Rain Quadro',
      author: 'BlueDelta',
      url: 'https://freesound.org/people/bluedelta/sounds/446753/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Thunder Long Rumbling No Rain',
      author: 'BlueDelta',
      url: 'https://freesound.org/people/bluedelta/sounds/367702/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Distant Thunder 3',
      author: 'Fission9',
      url: 'https://freesound.org/people/fission9/sounds/581124/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Crickets at Night Clean Sound',
      author: 'Defelozedd94',
      url: 'https://freesound.org/people/defelozedd94/sounds/522298/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Wind Blowing in the Countryside',
      author: 'Felix Blume',
      url: 'https://freesound.org/people/felixblume/sounds/215414/',
      license: 'CC0 1.0',
    ),
    // Water layers (Freesound)
    Attribution(
      title: 'Bird Chirps',
      author: 'keweldog',
      url: 'https://freesound.org/people/keweldog/sounds/181132/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Bird 07',
      author: 'LilMati',
      url: 'https://freesound.org/people/lilmati/sounds/519108/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Bird Whistling Single Robin A',
      author: 'InspectorJ',
      url: 'https://freesound.org/people/inspectorj/sounds/416529/',
      license: 'CC-BY 4.0',
    ),
    Attribution(
      title: 'Frog Croaking UK Common Frog',
      author: 'ShaunHillyard',
      url: 'https://freesound.org/people/shaunhillyard/sounds/532235/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'WindLeaves',
      author: 'o_ciz',
      url: 'https://freesound.org/people/o_ciz/sounds/475448/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'A Gentle Breeze Wind 3',
      author: 'mario1298',
      url: 'https://freesound.org/people/mario1298/sounds/181252/',
      license: 'CC0 1.0',
    ),
    Attribution(
      title: 'Soft Wind in the Trees Leaves Rustle',
      author: 'Borgory',
      url: 'https://freesound.org/people/borgory/sounds/751473/',
      license: 'CC0 1.0',
    ),
  ];
}
