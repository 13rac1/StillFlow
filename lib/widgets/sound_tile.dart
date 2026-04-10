import 'package:flutter/material.dart';
import '../models/sound.dart';

/// A tile widget representing a single sound in the library
///
/// Displays the sound name, description, and play/pause control
/// For EnvironmentSound, shows expandable layer controls
class SoundTile extends StatefulWidget {
  final Sound sound;
  final bool isPlaying;
  final VoidCallback onTap;
  final Set<String> enabledLayers;
  final Function(String layerId, bool enabled)? onLayerToggle;

  const SoundTile({
    super.key,
    required this.sound,
    required this.isPlaying,
    required this.onTap,
    this.enabledLayers = const {},
    this.onLayerToggle,
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
                  if (hasLayers && widget.isPlaying)
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
          if (hasLayers && widget.isPlaying && _isExpanded)
            _buildLayerControls(context),
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
            final isEnabled = widget.enabledLayers.contains(layer.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          layer.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isEnabled
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              layer.layerType == LayerType.continuous
                                  ? Icons.loop
                                  : Icons.bolt,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              layer.layerType == LayerType.continuous
                                  ? 'Continuous'
                                  : 'Random',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: widget.onLayerToggle != null
                        ? (value) {
                            widget.onLayerToggle!(layer.id, value);
                          }
                        : null,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
