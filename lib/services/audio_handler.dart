import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
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

  // Low-pass filter bounds (single source of truth shared with the UI sliders)
  static const double minLowPassFrequency = 500.0;
  static const double maxLowPassFrequency = 8000.0;
  static const double minLowPassResonance = 0.1;
  static const double maxLowPassResonance = 5.0;

  // Low-pass filter state
  bool _isLowPassEnabled = false;
  double _lowPassFrequency = 2000.0; // Hz (default cutoff)
  double _lowPassResonance = 1.0; // Sharpness of cutoff

  // Position tracking for long-running playback
  DateTime? _playbackStartTime;
  // Elapsed playback accumulated across pause/resume cycles. _playbackStartTime
  // only marks the current resume, so the reported position is this plus the
  // time since the last resume.
  Duration _accumulatedPosition = Duration.zero;
  Timer? _positionUpdateTimer;
  static const Duration _positionUpdateInterval = Duration(seconds: 30);

  // Track loaded audio sources
  final Map<String, AudioSource> _loadedSources = {};

  // Track active handles for base sound and layers
  SoundHandle? _baseHandle;
  final Map<String, SoundHandle> _continuousLayerHandles = {};
  final Map<String, Timer> _randomLayerTimers = {};
  final Map<String, List<AudioSource>> _randomLayerSources = {};

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

  /// Initialize the audio session and flutter_soloud
  ///
  /// Configures the platform [AudioSession] (mix-with-others, Android audio
  /// attributes, focus gain) BEFORE initializing SoLoud so media playback and
  /// audio focus behave correctly. If SoLoud fails to initialize (e.g. a
  /// lingering engine after a hot restart), it deinitializes and retries once.
  Future<void> initSoloud() async {
    if (_soloud.isInitialized) return;

    // Configure audio session for media playback and focus handling
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

    try {
      await _soloud.init();
      debugPrint('✅ flutter_soloud initialized in handler');
    } catch (e) {
      // Hot restart can leave a lingering engine; deinit and retry once.
      debugPrint('⚠️  flutter_soloud init error, retrying: $e');
      try {
        _soloud.deinit();
        await _soloud.init();
        debugPrint('✅ flutter_soloud initialized in handler on retry');
      } catch (retryError) {
        debugPrint('❌ Error initializing flutter_soloud after retry: $retryError');
        rethrow;
      }
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
      debugPrint('✅ Loaded audio: $assetPath');
      return audioSource;
    } catch (e) {
      debugPrint('❌ Error loading audio $assetPath: $e');
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
      mediaItem.add(
        MediaItem(
          id: sound.id,
          title: sound.name,
          artist: 'Still Flow',
          album: 'Ambient Sounds',
          duration: null, // Looping indefinitely
        ),
      );

      // Play with gapless looping
      final handle = _soloud.play(
        audioSource,
        volume: 1.0,
        looping: true,
        loopingStartAt: Duration.zero,
      );

      _baseHandle = handle;
      _currentSound = sound;

      // Start position tracking from zero for the newly started sound
      _accumulatedPosition = Duration.zero;
      _startPositionTracking();

      // Update playback state
      _updatePlaybackState(playing: true);

      debugPrint('🔊 Playing: ${sound.name} (gapless loop)');

      // If this is an EnvironmentSound, auto-enable default layers
      if (sound is EnvironmentSound) {
        for (final layer in sound.defaultEnabledLayers) {
          await toggleLayer(layer.id, true);
        }
        // Re-emit so listeners (e.g. HomeScreen's enabled-layer sync) observe
        // the auto-enabled layers instead of the pre-enable snapshot above.
        if (sound.defaultEnabledLayers.isNotEmpty) {
          _updatePlaybackState(playing: true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing sound: $e');
      rethrow;
    }
  }

  /// Toggle a layer on or off
  Future<void> toggleLayer(String layerId, bool enabled) async {
    if (_currentSound is! EnvironmentSound) {
      debugPrint('⚠️  Current sound is not an environment, cannot toggle layers');
      return;
    }

    final environment = _currentSound as EnvironmentSound;
    final layer = environment.getLayerById(layerId);

    if (layer == null) {
      debugPrint('⚠️  Layer $layerId not found');
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
      if (layer.layerType == LayerType.continuous) {
        final audioSource = await _loadAudioSource(layer.assetPaths.first);
        final volume = _randomInRange(layer.minVolume, layer.maxVolume);
        final pan = _randomInRange(layer.minPan, layer.maxPan);

        final handle = _soloud.play(
          audioSource,
          volume: volume,
          looping: true,
          loopingStartAt: Duration.zero,
        );

        _soloud.setPan(handle, pan);
        _continuousLayerHandles[layer.id] = handle;
        debugPrint(
          '🎵 Enabled continuous layer: ${layer.name} (vol: ${volume.toStringAsFixed(2)}, pan: ${pan.toStringAsFixed(2)})',
        );
      } else {
        // Load all variant sources for random selection
        final sources = <AudioSource>[];
        for (final path in layer.assetPaths) {
          sources.add(await _loadAudioSource(path));
        }
        _randomLayerSources[layer.id] = sources;
        _scheduleRandomEvent(layer);
        debugPrint(
          '⏰ Scheduled random layer: ${layer.name} (${sources.length} variants)',
        );
      }

      _enabledLayers.add(layer.id);
    } catch (e) {
      debugPrint('❌ Error enabling layer ${layer.name}: $e');
    }
  }

  /// Disable a layer (stop playing)
  Future<void> _disableLayer(String layerId) async {
    if (!_enabledLayers.contains(layerId)) {
      return; // Already disabled
    }

    if (_continuousLayerHandles.containsKey(layerId)) {
      _soloud.stop(_continuousLayerHandles[layerId]!);
      _continuousLayerHandles.remove(layerId);
    }

    if (_randomLayerTimers.containsKey(layerId)) {
      _randomLayerTimers[layerId]!.cancel();
      _randomLayerTimers.remove(layerId);
    }

    _randomLayerSources.remove(layerId);
    _enabledLayers.remove(layerId);
    debugPrint('🔇 Disabled layer: $layerId');
  }

  /// Schedule a random event to play
  void _scheduleRandomEvent(SoundLayer layer) {
    if (layer.minIntervalSeconds == null || layer.maxIntervalSeconds == null) {
      debugPrint('⚠️  Random layer ${layer.name} missing interval configuration');
      return;
    }

    final delaySeconds =
        _random.nextInt(
          layer.maxIntervalSeconds! - layer.minIntervalSeconds! + 1,
        ) +
        layer.minIntervalSeconds!;

    final timer = Timer(Duration(seconds: delaySeconds), () async {
      try {
        // Defense in depth: don't play or reschedule while paused/stopped.
        if (!playbackState.value.playing) return;

        final sources = _randomLayerSources[layer.id];
        if (sources == null || sources.isEmpty) return;

        // Pick a random variant
        final audioSource = sources[_random.nextInt(sources.length)];
        final volume = _randomInRange(layer.minVolume, layer.maxVolume);
        final pan = _randomInRange(layer.minPan, layer.maxPan);

        final handle = _soloud.play(
          audioSource,
          volume: volume,
          looping: false,
        );

        _soloud.setPan(handle, pan);
        debugPrint(
          '💥 Random event: ${layer.name} (vol: ${volume.toStringAsFixed(2)}, pan: ${pan.toStringAsFixed(2)})',
        );

        if (_enabledLayers.contains(layer.id)) {
          _scheduleRandomEvent(layer);
        }
      } catch (e) {
        debugPrint('❌ Error playing random event ${layer.name}: $e');
      }
    });

    // Replace any pending timer so duplicate play() calls can't stack events
    _randomLayerTimers[layer.id]?.cancel();
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
      // Resume base sound (absolute set so duplicate commands stay idempotent)
      _soloud.setPause(_baseHandle!, false);

      // Resume all continuous layers
      for (final handle in _continuousLayerHandles.values) {
        _soloud.setPause(handle, false);
      }

      // Restart random event cycles for any enabled random layers
      if (_currentSound is EnvironmentSound) {
        final environment = _currentSound as EnvironmentSound;
        for (final layerId in _enabledLayers) {
          final layer = environment.getLayerById(layerId);
          if (layer != null && layer.layerType == LayerType.random) {
            _scheduleRandomEvent(layer);
          }
        }
      }

      // Restart position tracking from current position
      _startPositionTracking();

      _updatePlaybackState(playing: true);
    } catch (e) {
      debugPrint('❌ Error resuming: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_baseHandle == null) return;

    try {
      // Pause base sound (absolute set so duplicate commands stay idempotent)
      _soloud.setPause(_baseHandle!, true);

      // Pause all continuous layers
      for (final handle in _continuousLayerHandles.values) {
        _soloud.setPause(handle, true);
      }

      // Cancel random event timers so one-shots stop firing while paused.
      // Sources and enabled state are left intact so play() can reschedule.
      for (final timer in _randomLayerTimers.values) {
        timer.cancel();
      }
      _randomLayerTimers.clear();

      // Bank elapsed time before stopping tracking so the reported position
      // doesn't reset to zero on the next resume.
      if (_playbackStartTime != null) {
        _accumulatedPosition += DateTime.now().difference(_playbackStartTime!);
      }

      // Stop position tracking while paused
      _stopPositionTracking();

      _updatePlaybackState(playing: false);
    } catch (e) {
      debugPrint('❌ Error pausing: $e');
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

      // Reset accumulated position for the next sound
      _accumulatedPosition = Duration.zero;

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
      debugPrint('⏹️  Stopped playback');
    } catch (e) {
      debugPrint('❌ Error stopping: $e');
    }
  }

  /// Total elapsed playback position, accounting for pause/resume cycles
  Duration get _currentPosition {
    final sinceResume = _playbackStartTime != null
        ? DateTime.now().difference(_playbackStartTime!)
        : Duration.zero;
    return _accumulatedPosition + sinceResume;
  }

  /// Start tracking playback position for long-running audio
  void _startPositionTracking() {
    _playbackStartTime = DateTime.now();
    _positionUpdateTimer?.cancel();

    // Update position every 30 seconds to keep MediaSession alive
    _positionUpdateTimer = Timer.periodic(_positionUpdateInterval, (timer) {
      if (_baseHandle != null && _playbackStartTime != null) {
        _updatePlaybackState(playing: true, position: _currentPosition);
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
    final currentPosition = position ?? _currentPosition;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: currentPosition,
        speed: 1.0,
      ),
    );
  }

  /// Set volume for base sound (0.0 to 1.0)
  void setVolume(double volume) {
    if (_baseHandle == null) return;

    try {
      _soloud.setVolume(_baseHandle!, volume);
    } catch (e) {
      debugPrint('❌ Error setting volume: $e');
    }
  }

  /// Get current volume of base sound
  double getVolume() {
    if (_baseHandle == null) return 1.0;

    try {
      return _soloud.getVolume(_baseHandle!);
    } catch (e) {
      debugPrint('❌ Error getting volume: $e');
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

      debugPrint(
        '🎛️  Low-pass filter enabled (${_lowPassFrequency.toInt()} Hz, resonance: ${_lowPassResonance.toStringAsFixed(1)})',
      );
    } else {
      // Deactivate filter
      _soloud.filters.biquadResonantFilter.deactivate();
      debugPrint('🎛️  Low-pass filter disabled');
    }
  }

  /// Set low-pass filter frequency (clamped to [minLowPassFrequency],
  /// [maxLowPassFrequency])
  void setLowPassFrequency(double frequency) {
    _lowPassFrequency = frequency.clamp(
      minLowPassFrequency,
      maxLowPassFrequency,
    );

    if (_isLowPassEnabled) {
      _soloud.filters.biquadResonantFilter.frequency.value = _lowPassFrequency;
      debugPrint('🎛️  Low-pass frequency: ${_lowPassFrequency.toInt()} Hz');
    }
  }

  /// Set low-pass filter resonance (clamped to [minLowPassResonance],
  /// [maxLowPassResonance])
  void setLowPassResonance(double resonance) {
    _lowPassResonance = resonance.clamp(
      minLowPassResonance,
      maxLowPassResonance,
    );

    if (_isLowPassEnabled) {
      _soloud.filters.biquadResonantFilter.resonance.value = _lowPassResonance;
      debugPrint('🎛️  Low-pass resonance: ${_lowPassResonance.toStringAsFixed(1)}');
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

      debugPrint('✅ Audio handler disposed');
    } catch (e) {
      debugPrint('❌ Error disposing audio handler: $e');
    }
  }
}
