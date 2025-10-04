import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/sound.dart';
import 'package:stillflow/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlayerService', () {
    late AudioPlayerService service;

    setUp(() {
      service = AudioPlayerService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should initialize with no current sound', () {
      expect(service.currentSound, isNull);
      expect(service.isPlaying, isFalse);
    });

    test('should have volume between 0.0 and 1.0', () {
      expect(service.volume, greaterThanOrEqualTo(0.0));
      expect(service.volume, lessThanOrEqualTo(1.0));
    });

    test('should expose required streams', () {
      expect(service.playingStream, isNotNull);
      expect(service.positionStream, isNotNull);
      expect(service.bufferedPositionStream, isNotNull);
      expect(service.durationStream, isNotNull);
    });

    test('setVolume should clamp to 0.0-1.0 range', () async {
      await service.setVolume(0.5);
      expect(service.volume, equals(0.5));

      await service.setVolume(1.5); // Over max
      expect(service.volume, lessThanOrEqualTo(1.0));

      await service.setVolume(-0.5); // Under min
      expect(service.volume, greaterThanOrEqualTo(0.0));
    });

    test('stop should clear current sound', () async {
      await service.stop();
      expect(service.currentSound, isNull);
    });

    // Note: Testing actual audio playback requires platform-specific setup
    // and audio files, so we're testing the service interface here.
    // Integration tests should verify actual audio playback.
  });
}
