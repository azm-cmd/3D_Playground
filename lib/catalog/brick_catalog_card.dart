import 'package:flutter/material.dart';

import 'brick_definition.dart';
import 'brick_preview.dart';

/// A single tappable catalog entry: preview swatch, name, and footprint.
class BrickCatalogCard extends StatelessWidget {
  final BrickDefinition brick;
  final bool highlighted;
  final VoidCallback? onTap;

  const BrickCatalogCard({
    super.key,
    required this.brick,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: highlighted,
      label: '${brick.name}, ${brick.shape.label}, ${brick.footprintLabel}',
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: highlighted ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: BrickPreview(brick: brick)),
                const SizedBox(height: 8),
                Text(
                  brick.name,
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  brick.footprintLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
