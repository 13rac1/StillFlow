import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:audio_session/audio_session.dart';
import '../models/sound.dart';

/// Audio service for gapless looping playback using flutter_soloud
///
/// flutter_soloud provides:
/// - True gapless looping at the native level
/// - Low-latency audio playback
/// - Background audio support
/// - Cross-platform consistency
class AudioService {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;

  AudioService._();

  final SoLoud _soloud = SoLoud.instance;

  // Track loaded sounds and their handles
  final Map<String, AudioSource> _loadedSounds = {};
  SoundHandle? _currentHandle;
  Sound? _currentSound;

  bool get isInitialized => _soloud.isInitialized;
  bool get isPlaying => _currentHandle != null;
  Sound? get currentSound => _currentSound;

  /// Initialize the audio engine
  Future<void> init() async {
    try {
      // Configure audio session for media controls
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      // Always try to initialize - SoLoud handles already-initialized state internally
      if (!_soloud.isInitialized) {
        await _soloud.init();
        print('✅ flutter_soloud initialized successfully');
      } else {
        print('✅ flutter_soloud already initialized');
      }
    } catch (e) {
      // If init fails, deinit and retry once
      print('⚠️  Initialization error, retrying: $e');
      try {
        _soloud.deinit();
        await _soloud.init();
        print('✅ flutter_soloud initialized successfully on retry');
      } catch (retryError) {
        print('❌ Error initializing flutter_soloud after retry: $retryError');
        rethrow;
      }
    }
  }

  /// Load a sound from assets
  Future<void> loadSound(Sound sound) async {
    if (!_soloud.isInitialized) {
      await init();
    }

    // Skip if already loaded
    if (_loadedSounds.containsKey(sound.id)) {
      return;
    }

    try {
      // Load with disk mode for better streaming of long files
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

      // Play with gapless looping
      final handle = await _soloud.play(
        audioSource,
        volume: 1.0,
        looping: true,
        loopingStartAt: Duration.zero,
      );

      _currentHandle = handle;
      _currentSound = sound;

      print('🔊 Playing: ${sound.name} (gapless loop enabled)');
    } catch (e) {
      print('❌ Error playing sound: $e');
      rethrow;
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    if (_currentHandle == null) return;

    try {
      _soloud.pauseSwitch(_currentHandle!);
      print('⏸️  Paused playback');
    } catch (e) {
      print('❌ Error pausing: $e');
    }
  }

  /// Resume current playback
  Future<void> resume() async {
    if (_currentHandle == null) return;

    try {
      _soloud.pauseSwitch(_currentHandle!);
      print('▶️  Resumed playback');
    } catch (e) {
      print('❌ Error resuming: $e');
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    if (_currentHandle == null) return;

    try {
      _soloud.stop(_currentHandle!);
      _currentHandle = null;
      _currentSound = null;
      print('⏹️  Stopped playback');
    } catch (e) {
      print('❌ Error stopping: $e');
    }
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

      // Deinitialize the engine
      _soloud.deinit();
      print('✅ Audio service disposed');
    } catch (e) {
      print('❌ Error disposing audio service: $e');
    }
  }
}
