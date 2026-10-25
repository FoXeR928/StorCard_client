import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/cards_viewmodel.dart';

class CardSearchEmptyState extends StatelessWidget {
  const CardSearchEmptyState({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Ничего не найдено', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'По запросу «$query» нет карт.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => context.read<CardsViewModel>().setQuery(''),
            icon: const Icon(Icons.clear),
            label: const Text('Сбросить поиск'),
          ),
        ],
      ),
    );
  }
}

class CardEmptyState extends StatelessWidget {
  const CardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Пока нет ни одной карты', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Нажми «+», чтобы добавить первую карту',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
