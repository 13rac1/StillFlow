import 'package:just_audio/just_audio.dart';
import '../models/sound.dart';

/// Service responsible for managing audio playback
///
/// This service handles:
/// - Playing sounds from the asset bundle
/// - Seamless looping
/// - Play/pause control
/// - Volume management
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  Sound? _currentSound;

  /// Currently playing sound (null if nothing is playing)
  Sound? get currentSound => _currentSound;

  /// Whether audio is currently playing
  bool get isPlaying => _player.playing;

  /// Stream of playback states
  Stream<bool> get playingStream => _player.playingStream;

  /// Stream of current position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of buffered position
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Stream of total duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Initialize the audio player with platform-specific settings
  Future<void> initialize() async {
    // Configure seamless looping
    await _player.setLoopMode(LoopMode.one);

    // Set audio session configuration for background playback
    // This will be expanded in Phase 3 with audio_service
  }

  /// Play a sound from the library
  ///
  /// [sound] - The sound to play
  /// Returns true if playback started successfully
  Future<bool> play(Sound sound) async {
    try {
      // If a different sound is requested, load it
      if (_currentSound?.id != sound.id) {
        await _player.setAsset(sound.assetPath);
        _currentSound = sound;
      }

      // Start playback
      await _player.play();
      return true;
    } catch (e) {
      // Log error and return false
      // In production, this should use proper logging
      print('Error playing sound: $e');
      return false;
    }
  }

  /// Pause the currently playing sound
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  /// Stop playback and clear current sound
  Future<void> stop() async {
    await _player.stop();
    _currentSound = null;
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    // Clamp volume between 0.0 and 1.0
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
  }

  /// Get current volume (0.0 to 1.0)
  double get volume => _player.volume;

  /// Dispose of resources
  Future<void> dispose() async {
    await _player.dispose();
  }
}
