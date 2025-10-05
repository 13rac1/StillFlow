import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/sound.dart';
import '../services/audio_handler.dart';
import '../widgets/sound_tile.dart';

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
          androidNotificationOngoing: true,
          androidShowNotificationBadge: false,
        ),
      );

      // Initialize flutter_soloud
      await _audioHandler!.initSoloud();

      // Listen to playback state changes
      _audioHandler!.playbackState.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
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
      print('❌ Audio service initialization failed: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Still Flow',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.7),
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
                          horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambient Sounds',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to play or pause',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
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
                      );
                    }),
                  ],
                ),
    );
  }
}
