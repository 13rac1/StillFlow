import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sound.dart';

/// Audio handler for background playback and media controls
///
/// This handler integrates with the platform's media session to provide:
/// - Background audio playback
/// - Lock screen controls
/// - Notification controls (Android)
/// - Control Center integration (iOS)
class StillFlowAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  Sound? _currentSound;

  StillFlowAudioHandler() {
    // Configure seamless looping
    _player.setLoopMode(LoopMode.one);

    // Listen to playback state changes and update media session
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Listen to processing state changes
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // For looping, this shouldn't happen, but handle it anyway
          break;
        case ProcessingState.ready:
          _broadcastState();
          break;
        default:
          _broadcastState();
          break;
      }
    });
  }

  /// Play a sound
  Future<void> playSound(Sound sound) async {
    try {
      // Update current sound
      _currentSound = sound;

      // Update media item for notification
      mediaItem.add(MediaItem(
        id: sound.id,
        title: sound.name,
        artist: 'Still Flow',
        album: 'Ambient Sounds',
        artUri: null, // Could add album art later
      ));

      // If a different sound is requested, load it
      await _player.setAsset(sound.assetPath);

      // Start playback
      await _player.play();
      _broadcastState();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentSound = null;
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Broadcast the current playback state to the media session
  void _broadcastState() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0], // Show play/pause in compact view
      processingState: _getProcessingState(),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  /// Map just_audio processing state to audio_service processing state
  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Get the underlying AudioPlayer for direct access if needed
  AudioPlayer get player => _player;

  /// Get the currently playing sound
  Sound? get currentSound => _currentSound;

  /// Dispose of resources
  Future<void> dispose() async {
    await _player.dispose();
  }
}
