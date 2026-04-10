import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/sound.dart';
import '../services/audio_handler.dart';
import '../widgets/sound_tile.dart';
import '../widgets/about_sheet.dart';
import '../widgets/equalizer_controls.dart';

/// Main screen displaying the sound library
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SoLoudAudioHandler? _audioHandler;
  bool _isLoading = true;
  bool _isPlaying = false;
  Set<String> _enabledLayers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      // Initialize audio service with our handler
      _audioHandler = await AudioService.init(
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

      // Listen to playback state changes and sync enabled layers
      _audioHandler!.playbackState.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _enabledLayers = _audioHandler?.enabledLayers ?? {};
          });
        }
      });

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
    _audioHandler?.dispose();
    super.dispose();
  }

  Future<void> _handleSoundTap(Sound sound) async {
    if (_audioHandler == null) return;

    // If tapping the currently playing sound, pause it
    if (_audioHandler!.currentSound?.id == sound.id && _isPlaying) {
      await _audioHandler!.pause();
      return;
    }

    // If tapping the current sound while paused, resume it
    if (_audioHandler!.currentSound?.id == sound.id && !_isPlaying) {
      await _audioHandler!.play();
      return;
    }

    // Otherwise, play the new sound
    await _audioHandler!.playSound(sound);
  }

  Future<void> _handleLayerToggle(String layerId, bool enabled) async {
    if (_audioHandler == null) return;

    await _audioHandler!.toggleLayer(layerId, enabled);

    // Update UI state
    setState(() {
      _enabledLayers = _audioHandler!.enabledLayers;
    });
  }

  void _showEqualizerControls() {
    if (_audioHandler == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EqualizerControls(audioHandler: _audioHandler!),
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
                  final isCurrentlyPlaying =
                      _audioHandler?.currentSound?.id == sound.id && _isPlaying;
                  return SoundTile(
                    sound: sound,
                    isPlaying: isCurrentlyPlaying,
                    onTap: () => _handleSoundTap(sound),
                    enabledLayers: _enabledLayers,
                    onLayerToggle: _handleLayerToggle,
                  );
                }),
              ],
            ),
    );
  }
}
