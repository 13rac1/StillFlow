import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillflow/models/mix_settings.dart';
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

    Future<void> pumpControls(
      WidgetTester tester, {
      ValueChanged<EqualizerSettings>? onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EqualizerControls(
              audioHandler: mockHandler,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    Future<void> expandAdvanced(WidgetTester tester) async {
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
    }

    testWidgets('should display title and description', (tester) async {
      await pumpControls(tester);

      expect(find.text('Low-Pass Filter'), findsOneWidget);
      expect(find.text('Reduce high frequency sounds'), findsOneWidget);
    });

    testWidgets('should show toggle switch', (tester) async {
      await pumpControls(tester);

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should toggle filter when switch is tapped', (tester) async {
      await pumpControls(tester);

      expect(mockHandler.isLowPassEnabled, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(mockHandler.isLowPassEnabled, isTrue);
    });

    group('presets', () {
      testWidgets('should show all preset options', (tester) async {
        await pumpControls(tester);

        expect(find.text('Clear'), findsOneWidget);
        expect(find.text('Warm'), findsOneWidget);
        expect(find.text('Muffled'), findsOneWidget);
      });

      testWidgets('Clear is highlighted when the filter is off', (
        tester,
      ) async {
        await pumpControls(tester);

        final button = tester.widget<SegmentedButton<int>>(
          find.byType(SegmentedButton<int>),
        );
        expect(button.selected, {0});
        expect(find.text('Custom'), findsNothing);
      });

      testWidgets('tapping Muffled enables the filter with preset values', (
        tester,
      ) async {
        EqualizerSettings? reported;
        await pumpControls(tester, onChanged: (s) => reported = s);

        await tester.tap(find.text('Muffled'));
        await tester.pump();

        expect(mockHandler.isLowPassEnabled, isTrue);
        expect(mockHandler.lowPassFrequency, 800);
        expect(mockHandler.lowPassResonance, 0.7);
        expect(reported?.enabled, isTrue);
        expect(reported?.frequency, 800);
      });

      testWidgets('tapping Clear disables the filter', (tester) async {
        mockHandler.setLowPassEnabled(true);
        await pumpControls(tester);

        await tester.tap(find.text('Clear'));
        await tester.pump();

        expect(mockHandler.isLowPassEnabled, isFalse);
      });

      testWidgets('diverging via advanced sliders shows Custom', (
        tester,
      ) async {
        // Warm preset values, filter on
        mockHandler.setLowPassEnabled(true);
        await pumpControls(tester);
        expect(find.text('Custom'), findsNothing);

        await expandAdvanced(tester);
        // Drag the frequency slider far right, away from any preset
        await tester.drag(find.byType(Slider).first, const Offset(300, 0));
        await tester.pump();

        expect(find.text('Custom'), findsOneWidget);
        final button = tester.widget<SegmentedButton<int>>(
          find.byType(SegmentedButton<int>),
        );
        expect(button.selected, isEmpty);
      });
    });

    group('advanced', () {
      testWidgets('sliders are hidden until Advanced is expanded', (
        tester,
      ) async {
        await pumpControls(tester);

        expect(find.byType(Slider), findsNothing);

        await expandAdvanced(tester);

        expect(find.byType(Slider), findsNWidgets(2));
        expect(find.text('Cutoff Frequency'), findsOneWidget);
        expect(find.text('2000 Hz'), findsOneWidget);
        expect(find.text('Resonance'), findsOneWidget);
        expect(find.text('1.0'), findsOneWidget);
      });

      testWidgets('should disable sliders when filter is off', (tester) async {
        await pumpControls(tester);
        await expandAdvanced(tester);

        final sliders = find.byType(Slider);
        expect(tester.widget<Slider>(sliders.first).onChanged, isNull);
        expect(tester.widget<Slider>(sliders.last).onChanged, isNull);
      });

      testWidgets('should enable sliders when filter is on', (tester) async {
        await pumpControls(tester);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await expandAdvanced(tester);

        final sliders = find.byType(Slider);
        expect(tester.widget<Slider>(sliders.first).onChanged, isNotNull);
        expect(tester.widget<Slider>(sliders.last).onChanged, isNotNull);
      });

      testWidgets('should show frequency range labels', (tester) async {
        await pumpControls(tester);
        await expandAdvanced(tester);

        expect(find.text('500 Hz'), findsOneWidget);
        expect(find.text('8000 Hz'), findsOneWidget);
      });

      testWidgets('should show resonance range labels', (tester) async {
        await pumpControls(tester);
        await expandAdvanced(tester);

        expect(find.text('Smooth'), findsOneWidget);
        expect(find.text('Sharp'), findsOneWidget);
      });

      testWidgets('should show helpful descriptions', (tester) async {
        await pumpControls(tester);
        await expandAdvanced(tester);

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
  });
}
