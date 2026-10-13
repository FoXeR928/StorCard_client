import 'package:flutter/material.dart';

import '../../admin/admin_all_cards_screen.dart';
import '../../admin/admin_users_screen.dart';

class SettingsAdminSection extends StatelessWidget {
  const SettingsAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.people_outline, color: scheme.primary),
          title: const Text('Пользователи'),
          subtitle: const Text('Просмотр, создание, роли, пароли'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
        ),
        ListTile(
          leading: Icon(Icons.card_membership, color: scheme.primary),
          title: const Text('Все карты'),
          subtitle: const Text('Карты всех пользователей'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminAllCardsScreen()),
          ),
        ),
      ],
    );
  }
}
