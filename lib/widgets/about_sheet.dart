import 'package:flutter/material.dart';
import '../models/sound.dart';

/// About sheet showing app info and audio attributions
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Text(
              'About Still Flow',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ambient sounds for sleep, focus, and relaxation.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Audio Credits header
            Text(
              'Audio Credits',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All sounds sourced from Freesound.org and Pixabay.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),

            // Attribution entries
            ...SoundLibrary.attributions.map(
              (a) => _AttributionTile(attribution: a),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _AttributionTile extends StatelessWidget {
  final Attribution attribution;

  const _AttributionTile({required this.attribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attribution.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${attribution.author}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: attribution.license.contains('CC-BY')
                  ? colorScheme.tertiaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attribution.license,
              style: textTheme.labelSmall?.copyWith(
                color: attribution.license.contains('CC-BY')
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
