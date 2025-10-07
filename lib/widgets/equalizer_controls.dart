import 'package:flutter/material.dart';
import '../services/audio_handler.dart';

/// Equalizer controls widget with low-pass filter
///
/// Provides UI controls for:
/// - Enable/disable low-pass filter
/// - Adjust cutoff frequency (500-8000 Hz)
/// - Adjust resonance (0.1-5.0)
class EqualizerControls extends StatefulWidget {
  final SoLoudAudioHandler audioHandler;

  const EqualizerControls({
    super.key,
    required this.audioHandler,
  });

  @override
  State<EqualizerControls> createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  late bool _isEnabled;
  late double _frequency;
  late double _resonance;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.audioHandler.isLowPassEnabled;
    _frequency = widget.audioHandler.lowPassFrequency;
    _resonance = widget.audioHandler.lowPassResonance;
  }

  void _toggleFilter(bool value) {
    setState(() {
      _isEnabled = value;
    });
    widget.audioHandler.setLowPassEnabled(value);
  }

  void _updateFrequency(double value) {
    setState(() {
      _frequency = value;
    });
    widget.audioHandler.setLowPassFrequency(value);
  }

  void _updateResonance(double value) {
    setState(() {
      _resonance = value;
    });
    widget.audioHandler.setLowPassResonance(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low-Pass Filter',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reduce high frequency sounds',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
              Switch(
                value: _isEnabled,
                onChanged: _toggleFilter,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Frequency slider
          AnimatedOpacity(
            opacity: _isEnabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cutoff Frequency',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_frequency.toInt()} Hz',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _frequency,
                  min: 500,
                  max: 8000,
                  divisions: 75, // 100 Hz steps
                  onChanged: _isEnabled ? _updateFrequency : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '500 Hz',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    Text(
                      '8000 Hz',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lower frequencies create a warmer, more muffled sound',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resonance slider
          AnimatedOpacity(
            opacity: _isEnabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resonance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _resonance.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _resonance,
                  min: 0.1,
                  max: 5.0,
                  divisions: 49,
                  onChanged: _isEnabled ? _updateResonance : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Smooth',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    Text(
                      'Sharp',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Controls the sharpness of the frequency cutoff',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
