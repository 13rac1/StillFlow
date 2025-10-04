import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/sound.dart';

void main() {
  group('Sound', () {
    test('should create sound with required properties', () {
      const sound = Sound(
        id: 'test',
        name: 'Test Sound',
        assetPath: 'assets/test.mp3',
        description: 'A test sound',
      );

      expect(sound.id, 'test');
      expect(sound.name, 'Test Sound');
      expect(sound.assetPath, 'assets/test.mp3');
      expect(sound.description, 'A test sound');
    });

    test('should compare sounds by id', () {
      const sound1 = Sound(
        id: 'test',
        name: 'Test Sound 1',
        assetPath: 'assets/test1.mp3',
        description: 'First test sound',
      );

      const sound2 = Sound(
        id: 'test',
        name: 'Test Sound 2',
        assetPath: 'assets/test2.mp3',
        description: 'Second test sound',
      );

      const sound3 = Sound(
        id: 'different',
        name: 'Different Sound',
        assetPath: 'assets/different.mp3',
        description: 'A different sound',
      );

      expect(sound1, equals(sound2)); // Same ID
      expect(sound1, isNot(equals(sound3))); // Different ID
    });

    test('should have consistent hashCode for same id', () {
      const sound1 = Sound(
        id: 'test',
        name: 'Test Sound 1',
        assetPath: 'assets/test1.mp3',
        description: 'First test sound',
      );

      const sound2 = Sound(
        id: 'test',
        name: 'Test Sound 2',
        assetPath: 'assets/test2.mp3',
        description: 'Second test sound',
      );

      expect(sound1.hashCode, equals(sound2.hashCode));
    });

    test('toString should return meaningful representation', () {
      const sound = Sound(
        id: 'rain',
        name: 'Rain',
        assetPath: 'assets/rain.mp3',
        description: 'Gentle rain',
      );

      expect(sound.toString(), contains('rain'));
      expect(sound.toString(), contains('Rain'));
    });
  });

  group('SoundLibrary', () {
    test('should have rain sound defined', () {
      expect(SoundLibrary.rain.id, 'rain');
      expect(SoundLibrary.rain.name, 'Rain');
      expect(SoundLibrary.rain.assetPath, isNotEmpty);
    });

    test('should have flowing water sound defined', () {
      expect(SoundLibrary.flowingWater.id, 'flowing_water');
      expect(SoundLibrary.flowingWater.name, 'Flowing Water');
      expect(SoundLibrary.flowingWater.assetPath, isNotEmpty);
    });

    test('all should contain all defined sounds', () {
      expect(SoundLibrary.all.length, 2);
      expect(SoundLibrary.all, contains(SoundLibrary.rain));
      expect(SoundLibrary.all, contains(SoundLibrary.flowingWater));
    });

    test('getById should return sound when id exists', () {
      final sound = SoundLibrary.getById('rain');
      expect(sound, isNotNull);
      expect(sound, equals(SoundLibrary.rain));
    });

    test('getById should return null when id does not exist', () {
      final sound = SoundLibrary.getById('nonexistent');
      expect(sound, isNull);
    });

    test('all sounds should have unique ids', () {
      final ids = SoundLibrary.all.map((s) => s.id).toSet();
      expect(ids.length, equals(SoundLibrary.all.length));
    });
  });
}
