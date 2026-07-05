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

  // --- 3D spatial audio ---
  // SoLoud's 3D rendering is stereo panning + distance attenuation. The
  // listener is placed once at the origin facing -Z (see [initSoloud]); every
  // 3D source is positioned relative to it. IMPORTANT: SoLoud's default
  // attenuation model is 0 (NO_ATTENUATION) — distance is inaudible unless a
  // model is set, so every 3D handle explicitly sets one below.
  static const int _attenuationLinear = 2; // SoLoud LINEAR_DISTANCE model

  // Wandering base loop (feature 1): the base environment loop drifts on a
  // gentle ellipse so the ambience feels alive without ever becoming
  // directional or faint. The ellipse is centered ahead of the listener, not
  // around them: SoLoud pans by direction ((dot(speaker, dir) + 1) / 2 per
  // ear), so a source passing directly beside the listener would land ~95/5
  // between ears. Keeping the source in front bounds the lateral angle to
  // ~24°, a worst-case inter-ear ratio near 1.7:1 (~4.6 dB) — a gentle drift.
  // Rolloff well under 1 with a generous max distance keeps the loop's volume
  // breathing to a few percent — the base loop must remain the dominant sound.
  static const double _wanderOrbitPeriodSeconds = 240.0; // 4-minute full orbit
  static const double _wanderCenterZ = -6.0; // orbit center, ahead (-Z)
  static const double _wanderRadiusX = 2.0; // left/right (pan) swing
  static const double _wanderRadiusZ = 1.5; // front/back swing (subtle)
  static const double _wanderMinDistance = 1.0; // full volume within this
  static const double _wanderMaxDistance = 30.0; // generous → gentle falloff
  static const double _wanderRolloff = 0.5; // well under 1 → subtle drift
  static const Duration _wanderUpdateInterval = Duration(milliseconds: 750);
  Timer? _wanderTimer;

  // Spatial one-shots (feature 2): random events (thunder, birdsong) spawn at
  // a random azimuth around the listener at a random distance chosen for the
  // layer's character. Attenuation is linear and gentle so the layer's own
  // volume randomization stays the dominant loudness cue while distance adds
  // subtle depth. min/max distance are generous so events are never silenced.
  static const double _oneShotMinDistance = 1.0; // full volume within this
  static const double _oneShotMaxDistance = 40.0; // generous → gentle falloff
  static const double _oneShotRolloff = 0.6; // subtle depth, still audible

  // Rolling thunder (feature 3): a thunder one-shot doesn't sit still — it
  // starts off to one side and sweeps across the sky (and recedes) over the
  // clip's own duration, so long rumbles "roll". Only the thunder layer rolls;
  // other one-shots stay at their static feature-2 position.
  static const double _thunderSweepArc = pi; // ~180° sweep across the sky
  static const double _thunderRecedeFactor = 1.6; // ends this× farther out
  static const Duration _thunderRollInterval = Duration(milliseconds: 500);

  // --- Audio interruption handling (calls, alarms, Siri, other apps) ---
  // Playback must survive interruptions (see CLAUDE.md: the sound stopping is
  // product failure). On iOS an interruption deactivates our audio session and
  // the OS never reactivates it for us — without listening for the end event,
  // reactivating, and resuming, a 20-second call means silence until morning.
  // Android delivers the equivalent audio-focus events through the same
  // stream. Desktop platforms emit no interruption events, so this is inert
  // there. Transient ducks (e.g. a navigation prompt) lower the global volume
  // instead of pausing — masking should continue quietly rather than stop.
  static const double _duckVolumeFactor = 0.3;
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _becomingNoisySubscription;
  bool _resumeOnInterruptionEnd = false;
  double? _volumeBeforeDuck;

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

  // Per-voice timers driving rolling-thunder motion (feature 3). Each cancels
  // itself when its clip ends; all are cancelled together by pause()/stop().
  final Set<Timer> _thunderRollTimers = {};

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
        // Deliver transient-can-duck focus losses as duck events (handled by
        // lowering volume) rather than converting them to pauses — a masking
        // app should get quieter for a navigation prompt, not stop.
        androidWillPauseWhenDucked: false,
      ),
    );
    _session = session;
    _attachAudioSessionListeners(session);

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

    // Establish an explicit 3D listener at the origin facing -Z. All 3D sources
    // (the wandering base loop and spatial one-shots) are positioned relative
    // to this listener. Set once here so 3D playback is deterministic.
    _soloud.set3dListenerPosition(0, 0, 0);
    _soloud.set3dListenerAt(0, 0, -1);
    _soloud.set3dListenerUp(0, 1, 0);
  }

  /// Attach interruption/route listeners exactly once (initSoloud can run
  /// again after a partial-failure retry; `??=` keeps this idempotent).
  void _attachAudioSessionListeners(AudioSession session) {
    _interruptionSubscription ??= session.interruptionEventStream.listen(
      _handleInterruptionEvent,
    );

    // A disappearing output route (headphones unplugged, Bluetooth earbuds
    // died mid-night) is deliberately a no-op: for a masking app, continuing
    // on the device speaker is the CORRECT behavior — the sound must never
    // stop. Do not add media-app-style auto-pause here.
    _becomingNoisySubscription ??= session.becomingNoisyEventStream.listen((_) {
      debugPrint('🔈 Output route lost — continuing playback (by design)');
    });
  }

  /// React to audio interruptions so playback survives them.
  ///
  /// Hard interruptions (phone call, alarm, Siri) pause playback and set a
  /// flag; when the OS signals the interruption ended with permission to
  /// resume, the session is reactivated (required on iOS) and playback
  /// resumes. Transient ducks lower the global volume instead of pausing.
  Future<void> _handleInterruptionEvent(AudioInterruptionEvent event) async {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          // Guard against repeated duck-begins so the pre-duck volume isn't
          // overwritten with an already-ducked value.
          if (_volumeBeforeDuck == null) {
            _volumeBeforeDuck = _soloud.getGlobalVolume();
            _soloud.setGlobalVolume(_volumeBeforeDuck! * _duckVolumeFactor);
            debugPrint('🔉 Ducked for transient interruption');
          }
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          // Only arm the resume flag when this interruption is what paused
          // us. A begin arriving while already paused (user pause, or a
          // nested interruption) must not clear a previously armed flag.
          if (playbackState.value.playing) {
            _resumeOnInterruptionEnd = true;
            await pause();
            debugPrint('⏸️  Paused by interruption; will resume when it ends');
          }
      }
      return;
    }

    switch (event.type) {
      case AudioInterruptionType.duck:
        final restore = _volumeBeforeDuck;
        if (restore != null) {
          _volumeBeforeDuck = null;
          _soloud.setGlobalVolume(restore);
          debugPrint('🔊 Restored volume after duck');
        }
      case AudioInterruptionType.pause:
        if (_resumeOnInterruptionEnd) {
          _resumeOnInterruptionEnd = false;
          // iOS deactivated the session for the interruption and will not
          // reactivate it for us; do so before resuming voices.
          try {
            await _session?.setActive(true);
          } catch (e) {
            debugPrint('⚠️  Could not reactivate audio session: $e');
          }
          await play();
          debugPrint('▶️  Resumed after interruption');
        }
      case AudioInterruptionType.unknown:
        // The OS declined to say we should resume (e.g. another media app
        // took over for good). The user chose that audio; respect it.
        _resumeOnInterruptionEnd = false;
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

      // Play with gapless looping as a 3D source so it can wander ahead of
      // the listener. Phase 0 places it at the near edge of the orbit,
      // directly in front (the listener faces -Z).
      final handle = _soloud.play3d(
        audioSource,
        0,
        0,
        _wanderCenterZ + _wanderRadiusZ,
        volume: 1.0,
        looping: true,
        loopingStartAt: Duration.zero,
      );
      _soloud.set3dSourceMinMaxDistance(
        handle,
        _wanderMinDistance,
        _wanderMaxDistance,
      );
      _soloud.set3dSourceAttenuation(handle, _attenuationLinear, _wanderRolloff);

      _baseHandle = handle;
      _currentSound = sound;

      // Start position tracking from zero for the newly started sound
      _accumulatedPosition = Duration.zero;
      _startPositionTracking();

      // Begin the slow orbit (derives its phase from the tracked position).
      _startWanderTimer();

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

        // Spawn on a circle around the listener. The layer's own
        // minVolume/maxVolume stays the play3d volume; distance attenuation
        // layers subtle depth on top.
        final range = _oneShotDistanceRange(layer);
        final distance = _randomInRange(range.near, range.far);
        final rolling = _isRollingThunderLayer(layer);

        // Rolling thunder starts off to one side (so it can sweep symmetrically
        // across the listener); other one-shots pick any point on the circle.
        final rollDirection = _random.nextBool() ? 1.0 : -1.0;
        final startAzimuth = rolling
            ? -rollDirection * _thunderSweepArc / 2
            : _random.nextDouble() * 2 * pi;
        final x = distance * sin(startAzimuth);
        final z = distance * cos(startAzimuth);

        final handle = _soloud.play3d(
          audioSource,
          x,
          0,
          z,
          volume: volume,
          looping: false,
        );
        _soloud.set3dSourceMinMaxDistance(
          handle,
          _oneShotMinDistance,
          _oneShotMaxDistance,
        );
        _soloud.set3dSourceAttenuation(
          handle,
          _attenuationLinear,
          _oneShotRolloff,
        );

        debugPrint(
          '💥 Random event: ${layer.name} '
          '(vol: ${volume.toStringAsFixed(2)}, '
          'dist: ${distance.toStringAsFixed(1)}, '
          'az: ${(startAzimuth * 180 / pi).toStringAsFixed(0)}°'
          '${rolling ? ', rolling' : ''})',
        );

        // Thunder rolls across the sky over its clip; others stay put.
        if (rolling) {
          _startThunderRoll(
            handle,
            audioSource,
            startAzimuth,
            rollDirection,
            distance,
          );
        }

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

  /// Start (or restart) the slow orbit of the base loop around the listener.
  ///
  /// Cancels any existing timer first so duplicate play() calls can't stack
  /// motion. The orbit phase is derived from the tracked playback position, so
  /// it naturally continues where it left off across pause/resume.
  void _startWanderTimer() {
    _wanderTimer?.cancel();
    _updateWanderPosition(); // apply immediately, don't wait a full interval
    _wanderTimer = Timer.periodic(
      _wanderUpdateInterval,
      (_) => _updateWanderPosition(),
    );
  }

  /// Move the base loop along its elliptical orbit based on elapsed playback
  /// time. A low update rate is plenty for minutes-long motion (battery).
  void _updateWanderPosition() {
    final handle = _baseHandle;
    if (handle == null) return;

    final tSeconds = _currentPosition.inMilliseconds / 1000.0;
    final phase = 2 * pi * (tSeconds / _wanderOrbitPeriodSeconds);
    final x = _wanderRadiusX * sin(phase);
    final z = _wanderCenterZ + _wanderRadiusZ * cos(phase);
    _soloud.set3dSourcePosition(handle, x, 0, z);
  }

  /// Spawn-distance range (near, far) for a one-shot layer, chosen by the
  /// layer's character. Thunder reads as distant weather so it spawns farther
  /// out; closer layers like birdsong spawn nearer. Kept as a handler-side
  /// heuristic to avoid bloating the Sound model.
  ({double near, double far}) _oneShotDistanceRange(SoundLayer layer) {
    if (_isRollingThunderLayer(layer)) return (near: 8.0, far: 20.0);
    return (near: 2.0, far: 8.0);
  }

  /// Whether a layer is the thunder layer, which gets distant spawns
  /// (feature 2) and rolling cross-sky motion (feature 3).
  bool _isRollingThunderLayer(SoundLayer layer) => layer.id == 'rain_thunder';

  /// Drive a rolling-thunder voice across the sky over its own clip duration.
  ///
  /// Sweeps the azimuth ~180° through the listener and recedes into the
  /// distance so long rumbles "roll". A low-rate timer moves the [handle] via
  /// set3dSourcePosition and cancels itself once the clip elapses, the voice
  /// becomes invalid, or playback stops; every such timer is also cancelled by
  /// pause()/stop() via [_thunderRollTimers].
  void _startThunderRoll(
    SoundHandle handle,
    AudioSource source,
    double startAzimuth,
    double rollDirection,
    double startDistance,
  ) {
    final totalMs = _soloud.getLength(source).inMilliseconds;
    if (totalMs <= 0) return; // unknown length → leave at its start position

    final spawnTime = DateTime.now();
    final timer = Timer.periodic(_thunderRollInterval, (t) {
      // Shared timer lifecycle: bail (and clean ourselves out of the tracking
      // set) once paused/stopped, the voice ends, or the clip elapses.
      final finished =
          !playbackState.value.playing ||
          !_soloud.getIsValidVoiceHandle(handle);
      final progress =
          (DateTime.now().difference(spawnTime).inMilliseconds / totalMs).clamp(
            0.0,
            1.0,
          );
      if (finished || progress >= 1.0) {
        t.cancel();
        _thunderRollTimers.remove(t);
        return;
      }

      final azimuth = startAzimuth + rollDirection * _thunderSweepArc * progress;
      final distance = startDistance * (1 + (_thunderRecedeFactor - 1) * progress);
      _soloud.set3dSourcePosition(
        handle,
        distance * sin(azimuth),
        0,
        distance * cos(azimuth),
      );
    });
    _thunderRollTimers.add(timer);
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

      // Resume the base loop's orbit (phase continues from tracked position).
      _startWanderTimer();

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

      // Stop the base loop's orbit while paused (resumed by play()).
      _wanderTimer?.cancel();
      _wanderTimer = null;

      // Cancel random event timers so one-shots stop firing while paused.
      // Sources and enabled state are left intact so play() can reschedule.
      for (final timer in _randomLayerTimers.values) {
        timer.cancel();
      }
      _randomLayerTimers.clear();

      // Stop any in-flight rolling-thunder motion (a resumed event that fires
      // again will start a fresh roll).
      for (final timer in _thunderRollTimers) {
        timer.cancel();
      }
      _thunderRollTimers.clear();

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

      // Stop the base loop's orbit
      _wanderTimer?.cancel();
      _wanderTimer = null;

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

      // Cancel all rolling-thunder motion timers
      for (final timer in _thunderRollTimers) {
        timer.cancel();
      }
      _thunderRollTimers.clear();

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
    // Bank any segment already in progress (duplicate play() while playing)
    // so restarting tracking never drops elapsed time.
    if (_playbackStartTime != null) {
      _accumulatedPosition += DateTime.now().difference(_playbackStartTime!);
    }
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
      // Stop listening to audio session events
      await _interruptionSubscription?.cancel();
      _interruptionSubscription = null;
      await _becomingNoisySubscription?.cancel();
      _becomingNoisySubscription = null;

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
