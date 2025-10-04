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

/// Built-in sound library for MVP
class SoundLibrary {
  static const Sound rain = Sound(
    id: 'rain',
    name: 'Rain',
    assetPath: 'assets/audio/rain-sounds-ambience-351115.mp3',
    description: 'Gentle rain ambience',
  );

  static const Sound flowingWater = Sound(
    id: 'flowing_water',
    name: 'Flowing Water',
    assetPath: 'assets/audio/flowing-water-loop-1-183953.mp3',
    description: 'Peaceful flowing water',
  );

  /// All available sounds for MVP
  static const List<Sound> all = [
    rain,
    flowingWater,
  ];

  /// Get a sound by ID
  static Sound? getById(String id) {
    try {
      return all.firstWhere((sound) => sound.id == id);
    } catch (_) {
      return null;
    }
  }
}
