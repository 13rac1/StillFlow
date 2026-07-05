import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/sound.dart';
import '../services/audio_handler.dart';
import '../services/settings_store.dart';
import '../widgets/sound_tile.dart';
import '../widgets/about_sheet.dart';
import '../widgets/equalizer_controls.dart';

/// Main screen displaying the sound library
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  SoLoudAudioHandler? _audioHandler;
  final SettingsStore _settingsStore = SettingsStore();
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;
  bool _playbackListenerAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudio();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist pending (debounced) settings before the OS may kill the process
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _settingsStore.flush();
    }
  }

  Future<void> _initializeAudio() async {
    try {
      // Load persisted settings first: independent of audio, and the tiles
      // need the restored mixes even if audio initialization fails.
      await _settingsStore.load();

      // Initialize audio service with our handler. audio_service only allows
      // one successful init() per process, so reuse the existing handler on
      // retry and re-run only the steps that failed.
      _audioHandler ??= await AudioService.init(
        builder: () => SoLoudAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.stillflow.audio',
          androidNotificationChannelName: 'Still Flow Audio',
          androidShowNotificationBadge: false,
          // Keep foreground service active even when paused to prevent
          // Android Doze mode from stopping media controls after hours.
          // Note: androidNotificationOngoing must be false when this is false.
          androidStopForegroundOnPause: false,
        ),
      );

      // Initialize flutter_soloud
      await _audioHandler!.initSoloud();

      // Restore the persisted equalizer. Must run after initSoloud() — the
      // enable path touches the live SoLoud filter. Frequency/resonance are
      // set first so enabling applies them.
      final equalizer = _settingsStore.equalizer;
      _audioHandler!.setLowPassFrequency(equalizer.frequency);
      _audioHandler!.setLowPassResonance(equalizer.resonance);
      if (equalizer.enabled) {
        _audioHandler!.setLowPassEnabled(true);
      }

      // Listen to playback state changes. Guard so a retry after a partial
      // failure doesn't subscribe a second time.
      if (!_playbackListenerAttached) {
        _audioHandler!.playbackState.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });
        _playbackListenerAttached = true;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize audio: $e';
        });
      }
      debugPrint('❌ Audio service initialization failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsStore.flush();
    _settingsStore.dispose();
    _audioHandler?.dispose();
    super.dispose();
  }

  /// Whether [sound] is the one currently audible — the condition for pushing
  /// mix changes to the handler live (otherwise they only go to the store,
  /// and the play/resume path reconciles).
  bool _isCurrentAndPlaying(Sound sound) =>
      _audioHandler?.currentSound?.id == sound.id && _isPlaying;

  Future<void> _handleSoundTap(Sound sound) async {
    if (_audioHandler == null) return;

    // If tapping the currently playing sound, pause it
    if (_audioHandler!.currentSound?.id == sound.id && _isPlaying) {
      await _audioHandler!.pause();
      return;
    }

    // If tapping the current sound while paused, resume it — and reconcile
    // to the stored mix, which may have been edited while paused.
    if (_audioHandler!.currentSound?.id == sound.id && !_isPlaying) {
      await _audioHandler!.play();
      if (sound is EnvironmentSound) {
        await _audioHandler!.applyMix(_settingsStore.mixFor(sound));
      }
      return;
    }

    // Otherwise, play the new sound with its stored mix
    await _audioHandler!.playSound(
      sound,
      mix: sound is EnvironmentSound ? _settingsStore.mixFor(sound) : null,
    );
    _settingsStore.recordLastSound(sound.id);
  }

  Future<void> _handleLayerToggle(
    EnvironmentSound sound,
    String layerId,
    bool enabled,
  ) async {
    final settings = _settingsStore.mixFor(sound).layers[layerId];
    if (settings == null) return;
    _settingsStore.updateLayer(
      sound.id,
      layerId,
      settings.copyWith(enabled: enabled),
    );

    // Only touch audible state when this sound is playing; toggling a layer
    // of a paused/other sound must not start audio.
    if (_isCurrentAndPlaying(sound)) {
      await _audioHandler!.toggleLayer(layerId, enabled);
    }
    setState(() {});
  }

  void _handleLayerVolume(
    EnvironmentSound sound,
    String layerId,
    double volume,
  ) {
    final settings = _settingsStore.mixFor(sound).layers[layerId];
    if (settings == null) return;
    _settingsStore.updateLayer(
      sound.id,
      layerId,
      settings.copyWith(volume: volume),
    );
    if (_isCurrentAndPlaying(sound)) {
      _audioHandler!.setLayerUserVolume(layerId, volume);
    }
    setState(() {});
  }

  void _handleLayerFrequency(
    EnvironmentSound sound,
    String layerId,
    double value, {
    required bool isFinal,
  }) {
    final settings = _settingsStore.mixFor(sound).layers[layerId];
    if (settings == null) return;
    _settingsStore.updateLayer(
      sound.id,
      layerId,
      settings.copyWith(frequency: value),
    );
    // The reschedule only happens when the drag ends, not per tick.
    if (isFinal && _isCurrentAndPlaying(sound)) {
      _audioHandler!.setLayerEventFrequency(layerId, value);
    }
    setState(() {});
  }

  void _showEqualizerControls() {
    if (_audioHandler == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EqualizerControls(
        audioHandler: _audioHandler!,
        onChanged: _settingsStore.updateEqualizer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Still Flow',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AboutSheet(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Equalizer',
            onPressed: _isLoading ? null : _showEqualizerControls,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _initializeAudio();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambient Sounds',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w300,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to play or pause',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Sound tiles
                ...SoundLibrary.all.map((sound) {
                  final environment = sound is EnvironmentSound ? sound : null;
                  return SoundTile(
                    sound: sound,
                    isPlaying: _isCurrentAndPlaying(sound),
                    onTap: () => _handleSoundTap(sound),
                    mixSettings: environment != null
                        ? _settingsStore.mixFor(environment)
                        : null,
                    onLayerToggle: environment != null
                        ? (layerId, enabled) =>
                              _handleLayerToggle(environment, layerId, enabled)
                        : null,
                    onLayerVolumeChanged: environment != null
                        ? (layerId, volume) =>
                              _handleLayerVolume(environment, layerId, volume)
                        : null,
                    onLayerFrequencyChanged: environment != null
                        ? (layerId, value) => _handleLayerFrequency(
                            environment,
                            layerId,
                            value,
                            isFinal: false,
                          )
                        : null,
                    onLayerFrequencyChangeEnd: environment != null
                        ? (layerId, value) => _handleLayerFrequency(
                            environment,
                            layerId,
                            value,
                            isFinal: true,
                          )
                        : null,
                  );
                }),
              ],
            ),
    );
  }
}
