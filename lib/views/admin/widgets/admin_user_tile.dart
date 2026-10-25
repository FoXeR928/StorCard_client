import 'package:flutter/material.dart';

import '../../../data/models/server_user.dart';
import '../admin_user_edit_screen.dart';

class AdminUserTile extends StatelessWidget {
  const AdminUserTile({super.key, required this.user, required this.isMe});
  final ServerUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isAdmin
            ? theme.colorScheme.primaryContainer
            : null,
        child: Icon(
          user.isAdmin ? Icons.shield : Icons.person,
          color: user.isAdmin ? theme.colorScheme.onPrimaryContainer : null,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(user.userName)),
          if (isMe)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Chip(
                label: Text('Вы', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (user.isAdmin)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('Админ', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      subtitle: Text(user.login),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminUserEditScreen(user: user)),
      ),
    );
  }
}
