import 'package:flutter/material.dart';

import '../../../data/models/server_admin_card.dart';

class AdminCardTile extends StatelessWidget {
  const AdminCardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onAction,
  });
  final ServerAdminCard card;
  final VoidCallback onTap;
  final void Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(card.name.isNotEmpty ? card.name[0].toUpperCase() : '?'),
      ),
      title: Text(card.name),
      subtitle: Text(
        card.ownerLogin == null
            ? card.barcode
            : '${card.ownerLogin} • ${card.barcode}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: onAction,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.qr_code_2),
              title: Text('Показать код'),
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: ListTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Поделиться'),
            ),
          ),
          PopupMenuItem(
            value: 'owner',
            child: ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text('Передать владение'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
