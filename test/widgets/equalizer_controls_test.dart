import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/widgets/equalizer_controls.dart';
import 'package:stillflow/services/audio_handler.dart';

// Mock audio handler for testing
class MockAudioHandler extends SoLoudAudioHandler {
  bool _lowPassEnabled = false;
  double _lowPassFrequency = 2000.0;
  double _lowPassResonance = 1.0;

  @override
  bool get isLowPassEnabled => _lowPassEnabled;

  @override
  double get lowPassFrequency => _lowPassFrequency;

  @override
  double get lowPassResonance => _lowPassResonance;

  @override
  void setLowPassEnabled(bool enabled) {
    _lowPassEnabled = enabled;
  }

  @override
  void setLowPassFrequency(double frequency) {
    _lowPassFrequency = frequency;
  }

  @override
  void setLowPassResonance(double resonance) {
    _lowPassResonance = resonance;
  }
}

void main() {
  group('EqualizerControls', () {
    late MockAudioHandler mockHandler;

    setUp(() {
      mockHandler = MockAudioHandler();
    });

    testWidgets('should display title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.text('Low-Pass Filter'), findsOneWidget);
      expect(find.text('Reduce high frequency sounds'), findsOneWidget);
    });

    testWidgets('should show toggle switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should toggle filter when switch is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(mockHandler.isLowPassEnabled, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(mockHandler.isLowPassEnabled, isTrue);
    });

    testWidgets('should display frequency slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.text('Cutoff Frequency'), findsOneWidget);
      expect(find.text('2000 Hz'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2)); // Frequency + Resonance
    });

    testWidgets('should display resonance slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.text('Resonance'), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);
    });

    testWidgets('should update frequency when slider changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      // Enable the filter first
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Find the frequency slider (first slider)
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));

      // The frequency slider should be enabled
      final frequencySlider = tester.widget<Slider>(sliders.first);
      expect(frequencySlider.onChanged, isNotNull);
    });

    testWidgets('should disable sliders when filter is off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      // Filter is off by default
      final sliders = find.byType(Slider);
      final frequencySlider = tester.widget<Slider>(sliders.first);
      final resonanceSlider = tester.widget<Slider>(sliders.last);

      expect(frequencySlider.onChanged, isNull);
      expect(resonanceSlider.onChanged, isNull);
    });

    testWidgets('should enable sliders when filter is on', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      // Enable the filter
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      final frequencySlider = tester.widget<Slider>(sliders.first);
      final resonanceSlider = tester.widget<Slider>(sliders.last);

      expect(frequencySlider.onChanged, isNotNull);
      expect(resonanceSlider.onChanged, isNotNull);
    });

    testWidgets('should show frequency range labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.text('500 Hz'), findsOneWidget);
      expect(find.text('8000 Hz'), findsOneWidget);
    });

    testWidgets('should show resonance range labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(find.text('Smooth'), findsOneWidget);
      expect(find.text('Sharp'), findsOneWidget);
    });

    testWidgets('should show helpful descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EqualizerControls(audioHandler: mockHandler)),
        ),
      );

      expect(
        find.text('Lower frequencies create a warmer, more muffled sound'),
        findsOneWidget,
      );
      expect(
        find.text('Controls the sharpness of the frequency cutoff'),
        findsOneWidget,
      );
    });
  });
}
