import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/sound.dart';

/// Audio handler that wraps flutter_soloud with audio_service for media controls
///
/// This combines:
/// - flutter_soloud: Native gapless looping with multi-layer support
/// - audio_service: System media controls and notifications
class SoLoudAudioHandler extends BaseAudioHandler {
  final SoLoud _soloud = SoLoud.instance;
  final Random _random = Random();

  // Low-pass filter state
  bool _isLowPassEnabled = false;
  double _lowPassFrequency = 2000.0; // Hz (default cutoff)
  double _lowPassResonance = 1.0; // Sharpness of cutoff

  // Position tracking for long-running playback
  DateTime? _playbackStartTime;
  Timer? _positionUpdateTimer;
  static const Duration _positionUpdateInterval = Duration(seconds: 30);

  // Track loaded audio sources
  final Map<String, AudioSource> _loadedSources = {};

  // Track active handles for base sound and layers
  SoundHandle? _baseHandle;
  final Map<String, SoundHandle> _continuousLayerHandles = {};
  final Map<String, Timer> _randomLayerTimers = {};

  // Current environment and enabled layers
  Sound? _currentSound;
  final Set<String> _enabledLayers = {};

  bool get isPlaying => _baseHandle != null && playbackState.value.playing;
  Sound? get currentSound => _currentSound;
  Set<String> get enabledLayers => Set.unmodifiable(_enabledLayers);

  // Low-pass filter getters
  bool get isLowPassEnabled => _isLowPassEnabled;
  double get lowPassFrequency => _lowPassFrequency;
  double get lowPassResonance => _lowPassResonance;

  /// Initialize flutter_soloud
  Future<void> initSoloud() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
      print('✅ flutter_soloud initialized in handler');
    }
  }

  /// Load an audio source from asset path
  Future<AudioSource> _loadAudioSource(String assetPath) async {
    if (!_soloud.isInitialized) {
      await initSoloud();
    }

    // Return cached source if already loaded
    if (_loadedSources.containsKey(assetPath)) {
      return _loadedSources[assetPath]!;
    }

    try {
      final audioSource = await _soloud.loadAsset(
        assetPath,
        mode: LoadMode.disk,
      );
      _loadedSources[assetPath] = audioSource;
      print('✅ Loaded audio: $assetPath');
      return audioSource;
    } catch (e) {
      print('❌ Error loading audio $assetPath: $e');
      rethrow;
    }
  }

  /// Play a sound (base loop only, without layers)
  Future<void> playSound(Sound sound) async {
    try {
      // Stop current playback if any
      if (_baseHandle != null) {
        await stop();
      }

      // Load and play base sound
      final audioSource = await _loadAudioSource(sound.assetPath);

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

      _baseHandle = handle;
      _currentSound = sound;

      // Start position tracking
      _startPositionTracking();

      // Update playback state
      _updatePlaybackState(playing: true);

      print('🔊 Playing: ${sound.name} (gapless loop)');

      // If this is an EnvironmentSound, auto-enable default layers
      if (sound is EnvironmentSound) {
        for (final layer in sound.defaultEnabledLayers) {
          await toggleLayer(layer.id, true);
        }
      }
    } catch (e) {
      print('❌ Error playing sound: $e');
      rethrow;
    }
  }

  /// Toggle a layer on or off
  Future<void> toggleLayer(String layerId, bool enabled) async {
    if (_currentSound is! EnvironmentSound) {
      print('⚠️  Current sound is not an environment, cannot toggle layers');
      return;
    }

    final environment = _currentSound as EnvironmentSound;
    final layer = environment.getLayerById(layerId);

    if (layer == null) {
      print('⚠️  Layer $layerId not found');
      return;
    }

    if (enabled) {
      await _enableLayer(layer);
    } else {
      await _disableLayer(layerId);
    }
  }

  /// Enable a layer (start playing)
  Future<void> _enableLayer(SoundLayer layer) async {
    if (_enabledLayers.contains(layer.id)) {
      return; // Already enabled
    }

    try {
      final audioSource = await _loadAudioSource(layer.assetPath);

      if (layer.layerType == LayerType.continuous) {
        // Continuous loop with random volume and pan
        final volume = _randomInRange(layer.minVolume, layer.maxVolume);
        final pan = _randomInRange(layer.minPan, layer.maxPan);

        final handle = await _soloud.play(
          audioSource,
          volume: volume,
          looping: true,
          loopingStartAt: Duration.zero,
        );

        // Set stereo pan position
        _soloud.setPan(handle, pan);

        _continuousLayerHandles[layer.id] = handle;
        print('🎵 Enabled continuous layer: ${layer.name} (vol: ${volume.toStringAsFixed(2)}, pan: ${pan.toStringAsFixed(2)})');
      } else {
        // Random event layer - set up timer
        _scheduleRandomEvent(layer, audioSource);
        print('⏰ Scheduled random layer: ${layer.name}');
      }

      _enabledLayers.add(layer.id);
    } catch (e) {
      print('❌ Error enabling layer ${layer.name}: $e');
    }
  }

  /// Disable a layer (stop playing)
  Future<void> _disableLayer(String layerId) async {
    if (!_enabledLayers.contains(layerId)) {
      return; // Already disabled
    }

    // Stop continuous layer if playing
    if (_continuousLayerHandles.containsKey(layerId)) {
      final handle = _continuousLayerHandles[layerId]!;
      _soloud.stop(handle);
      _continuousLayerHandles.remove(layerId);
    }

    // Cancel random event timer if active
    if (_randomLayerTimers.containsKey(layerId)) {
      _randomLayerTimers[layerId]!.cancel();
      _randomLayerTimers.remove(layerId);
    }

    _enabledLayers.remove(layerId);
    print('🔇 Disabled layer: $layerId');
  }

  /// Schedule a random event to play
  void _scheduleRandomEvent(SoundLayer layer, AudioSource audioSource) {
    if (layer.minIntervalSeconds == null || layer.maxIntervalSeconds == null) {
      print('⚠️  Random layer ${layer.name} missing interval configuration');
      return;
    }

    // Calculate random delay for next event
    final delaySeconds = _random.nextInt(
          layer.maxIntervalSeconds! - layer.minIntervalSeconds! + 1,
        ) +
        layer.minIntervalSeconds!;

    final timer = Timer(Duration(seconds: delaySeconds), () async {
      try {
        // Play one-shot with random volume and pan
        final volume = _randomInRange(layer.minVolume, layer.maxVolume);
        final pan = _randomInRange(layer.minPan, layer.maxPan);

        final handle = await _soloud.play(
          audioSource,
          volume: volume,
          looping: false, // One-shot playback
        );

        // Set stereo pan position
        _soloud.setPan(handle, pan);

        print('💥 Random event: ${layer.name} (vol: ${volume.toStringAsFixed(2)}, pan: ${pan.toStringAsFixed(2)})');

        // Schedule next event
        if (_enabledLayers.contains(layer.id)) {
          _scheduleRandomEvent(layer, audioSource);
        }
      } catch (e) {
        print('❌ Error playing random event ${layer.name}: $e');
      }
    });

    _randomLayerTimers[layer.id] = timer;
  }

  /// Get a random value within a range
  double _randomInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Set volume for a specific layer
  void setLayerVolume(String layerId, double volume) {
    if (_continuousLayerHandles.containsKey(layerId)) {
      final handle = _continuousLayerHandles[layerId]!;
      _soloud.setVolume(handle, volume);
    }
  }

  /// Set pan for a specific layer
  void setLayerPan(String layerId, double pan) {
    if (_continuousLayerHandles.containsKey(layerId)) {
      final handle = _continuousLayerHandles[layerId]!;
      _soloud.setPan(handle, pan);
    }
  }

  @override
  Future<void> play() async {
    if (_baseHandle == null) return;

    try {
      // Resume base sound
      _soloud.pauseSwitch(_baseHandle!);

      // Resume all continuous layers
      for (final handle in _continuousLayerHandles.values) {
        _soloud.pauseSwitch(handle);
      }

      // Restart position tracking from current position
      _startPositionTracking();

      _updatePlaybackState(playing: true);
    } catch (e) {
      print('❌ Error resuming: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_baseHandle == null) return;

    try {
      // Pause base sound
      _soloud.pauseSwitch(_baseHandle!);

      // Pause all continuous layers
      for (final handle in _continuousLayerHandles.values) {
        _soloud.pauseSwitch(handle);
      }

      // Stop position tracking while paused
      _stopPositionTracking();

      _updatePlaybackState(playing: false);
    } catch (e) {
      print('❌ Error pausing: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_baseHandle == null) return;

    try {
      // Stop position tracking
      _stopPositionTracking();

      // Stop base sound
      _soloud.stop(_baseHandle!);
      _baseHandle = null;

      // Stop all continuous layers
      for (final handle in _continuousLayerHandles.values) {
        _soloud.stop(handle);
      }
      _continuousLayerHandles.clear();

      // Cancel all random event timers
      for (final timer in _randomLayerTimers.values) {
        timer.cancel();
      }
      _randomLayerTimers.clear();

      _enabledLayers.clear();
      _currentSound = null;

      // Clear media item
      mediaItem.add(null);

      _updatePlaybackState(playing: false);
      print('⏹️  Stopped playback');
    } catch (e) {
      print('❌ Error stopping: $e');
    }
  }

  /// Start tracking playback position for long-running audio
  void _startPositionTracking() {
    _playbackStartTime = DateTime.now();
    _positionUpdateTimer?.cancel();

    // Update position every 30 seconds to keep MediaSession alive
    _positionUpdateTimer = Timer.periodic(_positionUpdateInterval, (timer) {
      if (_baseHandle != null && _playbackStartTime != null) {
        final elapsed = DateTime.now().difference(_playbackStartTime!);
        _updatePlaybackState(playing: true, position: elapsed);
      }
    });
  }

  /// Stop tracking playback position
  void _stopPositionTracking() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
    _playbackStartTime = null;
  }

  /// Update playback state for media controls
  void _updatePlaybackState({required bool playing, Duration? position}) {
    final currentPosition = position ??
        (_playbackStartTime != null
            ? DateTime.now().difference(_playbackStartTime!)
            : Duration.zero);

    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: currentPosition,
      speed: 1.0,
    ));
  }

  /// Set volume for base sound (0.0 to 1.0)
  void setVolume(double volume) {
    if (_baseHandle == null) return;

    try {
      _soloud.setVolume(_baseHandle!, volume);
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }

  /// Get current volume of base sound
  double getVolume() {
    if (_baseHandle == null) return 1.0;

    try {
      return _soloud.getVolume(_baseHandle!);
    } catch (e) {
      print('❌ Error getting volume: $e');
      return 1.0;
    }
  }

  /// Enable/disable low-pass filter globally
  void setLowPassEnabled(bool enabled) {
    _isLowPassEnabled = enabled;

    if (enabled) {
      // Activate biquad filter in LOWPASS mode
      _soloud.filters.biquadResonantFilter.activate();

      // Set filter parameters
      _soloud.filters.biquadResonantFilter.type.value = 0.0; // LOWPASS = 0
      _soloud.filters.biquadResonantFilter.frequency.value = _lowPassFrequency;
      _soloud.filters.biquadResonantFilter.resonance.value = _lowPassResonance;

      print('🎛️  Low-pass filter enabled (${_lowPassFrequency.toInt()} Hz, resonance: ${_lowPassResonance.toStringAsFixed(1)})');
    } else {
      // Deactivate filter
      _soloud.filters.biquadResonantFilter.deactivate();
      print('🎛️  Low-pass filter disabled');
    }
  }

  /// Set low-pass filter frequency (10-16000 Hz)
  void setLowPassFrequency(double frequency) {
    _lowPassFrequency = frequency.clamp(10.0, 16000.0);

    if (_isLowPassEnabled) {
      _soloud.filters.biquadResonantFilter.frequency.value = _lowPassFrequency;
      print('🎛️  Low-pass frequency: ${_lowPassFrequency.toInt()} Hz');
    }
  }

  /// Set low-pass filter resonance (0.1-20)
  void setLowPassResonance(double resonance) {
    _lowPassResonance = resonance.clamp(0.1, 20.0);

    if (_isLowPassEnabled) {
      _soloud.filters.biquadResonantFilter.resonance.value = _lowPassResonance;
      print('🎛️  Low-pass resonance: ${_lowPassResonance.toStringAsFixed(1)}');
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    try {
      // Stop position tracking timer
      _stopPositionTracking();

      if (_baseHandle != null) {
        await stop();
      }

      // Dispose all loaded sources
      for (final audioSource in _loadedSources.values) {
        await _soloud.disposeSource(audioSource);
      }
      _loadedSources.clear();

      print('✅ Audio handler disposed');
    } catch (e) {
      print('❌ Error disposing audio handler: $e');
    }
  }
}
