import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  final Cards card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          card.name.isNotEmpty ? card.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(card.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        card.barcode,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
