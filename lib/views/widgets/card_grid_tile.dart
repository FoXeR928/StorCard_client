import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';
import 'card_image.dart';

class CardGridTile extends StatelessWidget {
  const CardGridTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onLongPress,
  });

  final Cards card;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = card.image?.isNotEmpty == true;

    // В тёмной теме чуть светлее фона, в светлой — чуть темнее.
    final tileColor = isDark
        ? Color.alphaBlend(
            scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            scheme.surface,
          )
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // В тёмной теме граница ярче — чтобы плитка отделилась от фона.
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Картинка или иконка-заглушка
              Expanded(
                child: hasImage
                    ? CardImage(raw: card.image!, fit: BoxFit.cover)
                    : _NoImagePlaceholder(),
              ),
              // Название снизу — тот же фон, что у плитки, без резкой полосы
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.credit_card_outlined,
        size: 48,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
