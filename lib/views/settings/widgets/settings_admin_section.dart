import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/dialogs.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/backup_service.dart';
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
        ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
          title: const Text('Экспорт для миграции сервера'),
          subtitle: const Text('Выгрузить ВСЕХ пользователей и карты'),
          onTap: () async {
            final pass = await promptDialog(
              context,
              title: 'Миграция сервера',
              label: 'Задайте пароль для архива',
              obscure: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
            );
            if (pass == null || pass.isEmpty || !context.mounted) return;

            showSnack(context, 'Подготовка данных...');
            final data = await context
                .read<AdminService>()
                .prepareMigrationData();

            if (!context.mounted) return;
            if (data == null) {
              showSnack(context, 'Ошибка при сборе данных', error: true);
              return;
            }

            final ok = await BackupService.instance.exportToFile(
              data: data,
              password: pass,
              filenamePrefix: 'server_migration',
            );

            if (context.mounted) {
              if (ok) {
                showSnack(context, 'Файл миграции готов');
              } else {
                showSnack(context, 'Ошибка при создании файла', error: true);
              }
            }
          },
        ),
      ],
    );
  }
}
