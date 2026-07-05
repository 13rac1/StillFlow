import 'package:flutter/material.dart';
import '../models/mix_settings.dart';
import '../services/audio_handler.dart';

/// A preset for the low-pass filter. [frequency]/[resonance] are null for
/// the filter-off preset.
class _EqualizerPreset {
  final String label;
  final String description;
  final bool enabled;
  final double? frequency;
  final double? resonance;

  const _EqualizerPreset(
    this.label,
    this.description, {
    required this.enabled,
    this.frequency,
    this.resonance,
  });
}

/// Equalizer controls widget with low-pass filter
///
/// Preset-first UI (Clear / Warm / Muffled); the underlying cutoff-frequency
/// and resonance sliders live under an "Advanced" expander. Reports every
/// change through [onChanged] so the caller can persist it.
class EqualizerControls extends StatefulWidget {
  final SoLoudAudioHandler audioHandler;
  final ValueChanged<EqualizerSettings>? onChanged;

  const EqualizerControls({
    super.key,
    required this.audioHandler,
    this.onChanged,
  });

  @override
  State<EqualizerControls> createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  static const List<_EqualizerPreset> _presets = [
    _EqualizerPreset('Clear', 'Full brightness', enabled: false),
    _EqualizerPreset(
      'Warm',
      'Softens hiss',
      enabled: true,
      frequency: 2000,
      resonance: 1.0,
    ),
    _EqualizerPreset(
      'Muffled',
      'Through-the-wall',
      enabled: true,
      frequency: 800,
      resonance: 0.7,
    ),
  ];

  // Tolerances are half a slider step (100 Hz / 0.1), so a value that can
  // only have come from a preset still matches it after a round trip.
  static const double _frequencyTolerance = 50.0;
  static const double _resonanceTolerance = 0.05;

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

  /// Index into [_presets] matching the current values, or null ("Custom").
  int? get _activePresetIndex {
    if (!_isEnabled) return 0;
    for (var i = 1; i < _presets.length; i++) {
      final preset = _presets[i];
      if ((_frequency - preset.frequency!).abs() <= _frequencyTolerance &&
          (_resonance - preset.resonance!).abs() <= _resonanceTolerance) {
        return i;
      }
    }
    return null;
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      EqualizerSettings(
        enabled: _isEnabled,
        frequency: _frequency,
        resonance: _resonance,
      ),
    );
  }

  void _applyPreset(_EqualizerPreset preset) {
    setState(() {
      if (preset.enabled) {
        _frequency = preset.frequency!;
        _resonance = preset.resonance!;
      }
      _isEnabled = preset.enabled;
    });
    // Values first so enabling activates the filter with them already set
    if (preset.enabled) {
      widget.audioHandler.setLowPassFrequency(_frequency);
      widget.audioHandler.setLowPassResonance(_resonance);
    }
    widget.audioHandler.setLowPassEnabled(preset.enabled);
    _notifyChanged();
  }

  void _toggleFilter(bool value) {
    setState(() {
      _isEnabled = value;
    });
    widget.audioHandler.setLowPassEnabled(value);
    _notifyChanged();
  }

  void _updateFrequency(double value) {
    setState(() {
      _frequency = value;
    });
    widget.audioHandler.setLowPassFrequency(value);
    _notifyChanged();
  }

  void _updateResonance(double value) {
    setState(() {
      _resonance = value;
    });
    widget.audioHandler.setLowPassResonance(value);
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    // A Material (not a decorated Container) so the ExpansionTile's ink and
    // background render against it correctly.
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reduce high frequency sounds',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Switch(value: _isEnabled, onChanged: _toggleFilter),
                ],
              ),
              const SizedBox(height: 24),

              // Presets
              _buildPresets(context),
              const SizedBox(height: 16),

              // Advanced sliders
              _buildAdvanced(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresets(BuildContext context) {
    final activeIndex = _activePresetIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: [
              for (var i = 0; i < _presets.length; i++)
                ButtonSegment(
                  value: i,
                  label: Text(_presets[i].label),
                  tooltip: _presets[i].description,
                ),
            ],
            selected: {?activeIndex},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                _applyPreset(_presets[selection.first]);
              }
            },
          ),
        ),
        if (activeIndex == null) ...[
          const SizedBox(height: 8),
          Text(
            'Custom',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvanced(BuildContext context) {
    return Theme(
      // Remove the ExpansionTile's top/bottom dividers
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text('Advanced', style: Theme.of(context).textTheme.titleMedium),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          _buildFrequencySlider(context),
          const SizedBox(height: 24),
          _buildResonanceSlider(context),
        ],
      ),
    );
  }

  Widget _buildFrequencySlider(BuildContext context) {
    return AnimatedOpacity(
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
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _frequency,
            min: SoLoudAudioHandler.minLowPassFrequency,
            max: SoLoudAudioHandler.maxLowPassFrequency,
            divisions: 75, // 100 Hz steps
            onChanged: _isEnabled ? _updateFrequency : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${SoLoudAudioHandler.minLowPassFrequency.toInt()} Hz',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${SoLoudAudioHandler.maxLowPassFrequency.toInt()} Hz',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lower frequencies create a warmer, more muffled sound',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResonanceSlider(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isEnabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resonance', style: Theme.of(context).textTheme.titleMedium),
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
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _resonance,
            min: SoLoudAudioHandler.minLowPassResonance,
            max: SoLoudAudioHandler.maxLowPassResonance,
            divisions: 49, // 0.1 resonance steps
            onChanged: _isEnabled ? _updateResonance : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smooth',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Sharp',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Controls the sharpness of the frequency cutoff',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
