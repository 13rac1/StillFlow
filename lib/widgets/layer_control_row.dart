import 'package:flutter/material.dart';
import '../models/mix_settings.dart';
import '../models/sound.dart';

/// Controls for a single layer within a sound tile: an enable switch, a
/// volume slider, and — for random layers — an event-frequency slider
/// (Rare ↔ Often). Sliders stay visible but disabled when the layer is off
/// so the user's values aren't hidden by toggling.
class LayerControlRow extends StatelessWidget {
  final SoundLayer layer;
  final LayerSettings settings;
  final ValueChanged<bool> onToggle;

  /// Called per drag tick; safe to apply live (volume changes are cheap).
  final ValueChanged<double> onVolumeChanged;

  /// Called per drag tick for display/persistence only.
  final ValueChanged<double>? onFrequencyChanged;

  /// Called when the drag ends; the expensive reschedule happens here.
  final ValueChanged<double>? onFrequencyChangeEnd;

  const LayerControlRow({
    super.key,
    required this.layer,
    required this.settings,
    required this.onToggle,
    required this.onVolumeChanged,
    this.onFrequencyChanged,
    this.onFrequencyChangeEnd,
  });

  bool get _isRandom => layer.layerType == LayerType.random;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = settings.enabled;
    final dimmed = colorScheme.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: enabled ? colorScheme.onSurface : dimmed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _isRandom ? Icons.bolt : Icons.loop,
                        size: 12,
                        color: dimmed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRandom ? 'Occasional' : 'Ambience',
                        style: textTheme.bodySmall?.copyWith(color: dimmed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: colorScheme.primary,
            ),
          ],
        ),
        AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.volume_down, size: 18, color: dimmed),
                    Expanded(
                      child: Slider(
                        value: settings.volume,
                        onChanged: enabled ? onVolumeChanged : null,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(settings.volume * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall?.copyWith(color: dimmed),
                      ),
                    ),
                  ],
                ),
                if (_isRandom)
                  Row(
                    children: [
                      Text(
                        'Rare',
                        style: textTheme.bodySmall?.copyWith(color: dimmed),
                      ),
                      Expanded(
                        child: Slider(
                          value: settings.frequency,
                          onChanged: enabled ? onFrequencyChanged : null,
                          onChangeEnd: enabled ? onFrequencyChangeEnd : null,
                        ),
                      ),
                      Text(
                        'Often',
                        style: textTheme.bodySmall?.copyWith(color: dimmed),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
