import 'package:flutter/material.dart';

/// Заголовок секции. Используется в настройках и админских экранах.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.accent = false});
  final String title;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
