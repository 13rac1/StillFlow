import 'package:flutter/material.dart';
import '../models/mix_settings.dart';
import '../models/sound.dart';
import 'layer_control_row.dart';

/// A tile widget representing a single sound in the library
///
/// Displays the sound name, description, and play/pause control.
/// For EnvironmentSound, shows expandable layer controls (switch, volume,
/// and event-frequency sliders) — available whether or not the sound is
/// playing, so a mix can be configured before pressing play.
class SoundTile extends StatefulWidget {
  final Sound sound;
  final bool isPlaying;
  final VoidCallback onTap;

  /// Desired mix for this sound (from the settings store). Falls back to the
  /// layers' authored defaults when null.
  final SoundMixSettings? mixSettings;
  final Function(String layerId, bool enabled)? onLayerToggle;
  final Function(String layerId, double volume)? onLayerVolumeChanged;
  final Function(String layerId, double value)? onLayerFrequencyChanged;
  final Function(String layerId, double value)? onLayerFrequencyChangeEnd;

  const SoundTile({
    super.key,
    required this.sound,
    required this.isPlaying,
    required this.onTap,
    this.mixSettings,
    this.onLayerToggle,
    this.onLayerVolumeChanged,
    this.onLayerFrequencyChanged,
    this.onLayerFrequencyChangeEnd,
  });

  @override
  State<SoundTile> createState() => _SoundTileState();
}

class _SoundTileState extends State<SoundTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasLayers =
        widget.sound is EnvironmentSound &&
        (widget.sound as EnvironmentSound).layers.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon representing the sound state
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isPlaying
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: widget.isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.isPlaying
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sound name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sound.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: widget.isPlaying
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: widget.isPlaying
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.sound.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Visual indicator for playing state
                  if (widget.isPlaying)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  // Expand/collapse button for environment sounds
                  if (hasLayers)
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          // Layer controls (expandable)
          if (hasLayers && _isExpanded) _buildLayerControls(context),
        ],
      ),
    );
  }

  Widget _buildLayerControls(BuildContext context) {
    final environment = widget.sound as EnvironmentSound;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Sound Layers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...environment.layers.map((layer) {
            final settings =
                widget.mixSettings?.layers[layer.id] ??
                LayerSettings(enabled: layer.enabledByDefault);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LayerControlRow(
                layer: layer,
                settings: settings,
                onToggle: (enabled) =>
                    widget.onLayerToggle?.call(layer.id, enabled),
                onVolumeChanged: (volume) =>
                    widget.onLayerVolumeChanged?.call(layer.id, volume),
                onFrequencyChanged: (value) =>
                    widget.onLayerFrequencyChanged?.call(layer.id, value),
                onFrequencyChangeEnd: (value) =>
                    widget.onLayerFrequencyChangeEnd?.call(layer.id, value),
              ),
            );
          }),
        ],
      ),
    );
  }
}
