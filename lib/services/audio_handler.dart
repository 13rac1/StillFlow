import 'package:audio_service/audio_service.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/sound.dart';

/// Audio handler that wraps flutter_soloud with audio_service for media controls
///
/// This combines:
/// - flutter_soloud: Native gapless looping
/// - audio_service: System media controls and notifications
class SoLoudAudioHandler extends BaseAudioHandler {
  final SoLoud _soloud = SoLoud.instance;

  // Track loaded sounds and their handles
  final Map<String, AudioSource> _loadedSounds = {};
  SoundHandle? _currentHandle;
  Sound? _currentSound;

  bool get isPlaying => _currentHandle != null && playbackState.value.playing;
  Sound? get currentSound => _currentSound;

  /// Initialize flutter_soloud
  Future<void> initSoloud() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
      print('✅ flutter_soloud initialized in handler');
    }
  }

  /// Load a sound from assets
  Future<void> loadSound(Sound sound) async {
    if (!_soloud.isInitialized) {
      await initSoloud();
    }

    // Skip if already loaded
    if (_loadedSounds.containsKey(sound.id)) {
      return;
    }

    try {
      final audioSource = await _soloud.loadAsset(
        sound.assetPath,
        mode: LoadMode.disk,
      );
      _loadedSounds[sound.id] = audioSource;
      print('✅ Loaded sound: ${sound.name}');
    } catch (e) {
      print('❌ Error loading sound ${sound.name}: $e');
      rethrow;
    }
  }

  /// Play a sound with gapless looping
  Future<void> playSound(Sound sound) async {
    try {
      // Stop current playback if any
      if (_currentHandle != null) {
        await stop();
      }

      // Load sound if not already loaded
      await loadSound(sound);

      final audioSource = _loadedSounds[sound.id]!;

      // Update media item for notification
      mediaItem.add(MediaItem(
        id: sound.id,
        title: sound.name,
        artist: 'Still Flow',
        album: 'Ambient Sounds',
        duration: null, // Looping indefinitely
      ));

      // Play with gapless looping
      final handle = await _soloud.play(
        audioSource,
        volume: 1.0,
        looping: true,
        loopingStartAt: Duration.zero,
      );

      _currentHandle = handle;
      _currentSound = sound;

      // Update playback state
      _updatePlaybackState(playing: true);

      print('🔊 Playing: ${sound.name} (gapless loop)');
    } catch (e) {
      print('❌ Error playing sound: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    if (_currentHandle == null) return;

    try {
      _soloud.pauseSwitch(_currentHandle!);
      _updatePlaybackState(playing: true);
    } catch (e) {
      print('❌ Error resuming: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_currentHandle == null) return;

    try {
      _soloud.pauseSwitch(_currentHandle!);
      _updatePlaybackState(playing: false);
    } catch (e) {
      print('❌ Error pausing: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_currentHandle == null) return;

    try {
      _soloud.stop(_currentHandle!);
      _currentHandle = null;
      _currentSound = null;

      // Clear media item
      mediaItem.add(null);

      _updatePlaybackState(playing: false);
      print('⏹️  Stopped playback');
    } catch (e) {
      print('❌ Error stopping: $e');
    }
  }

  /// Update playback state for media controls
  void _updatePlaybackState({required bool playing}) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: Duration.zero,
      speed: 1.0,
    ));
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    if (_currentHandle == null) return;

    try {
      _soloud.setVolume(_currentHandle!, volume);
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }

  /// Get current volume
  double getVolume() {
    if (_currentHandle == null) return 1.0;

    try {
      return _soloud.getVolume(_currentHandle!);
    } catch (e) {
      print('❌ Error getting volume: $e');
      return 1.0;
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    try {
      if (_currentHandle != null) {
        await stop();
      }

      // Dispose all loaded sounds
      for (final audioSource in _loadedSounds.values) {
        await _soloud.disposeSource(audioSource);
      }
      _loadedSounds.clear();

      print('✅ Audio handler disposed');
    } catch (e) {
      print('❌ Error disposing audio handler: $e');
    }
  }
}
