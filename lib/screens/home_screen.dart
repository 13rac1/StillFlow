import 'package:flutter/material.dart';
import '../models/sound.dart';
import '../services/audio_player_service.dart';
import '../widgets/sound_tile.dart';

/// Main screen displaying the sound library
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  Sound? _currentSound;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();

    // Listen to playing state changes
    _audioService.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _handleSoundTap(Sound sound) async {
    // If tapping the currently playing sound, pause it
    if (_currentSound?.id == sound.id && _isPlaying) {
      await _audioService.pause();
      return;
    }

    // If tapping the current sound while paused, resume it
    if (_currentSound?.id == sound.id && !_isPlaying) {
      await _audioService.resume();
      return;
    }

    // Otherwise, play the new sound
    setState(() {
      _currentSound = sound;
    });
    await _audioService.play(sound);
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ambient Sounds',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to play or pause',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                _currentSound?.id == sound.id && _isPlaying;
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
