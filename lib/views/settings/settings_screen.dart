import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/section_header.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import '../../viewmodels/cards_viewmodel.dart';
import 'widgets/settings_account_section.dart';
import 'widgets/settings_admin_section.dart';
import 'widgets/settings_app_section.dart';
import 'widgets/settings_sync_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SectionHeader('Аккаунт'),
          SettingsAccountSection(auth: auth),

          const SectionHeader('Синхронизация'),
          SettingsSyncSection(sync: sync, auth: auth),

          const SectionHeader('Данные'),
          const _CardsCountTile(),

          if (auth.isAdmin) ...[
            const SectionHeader('Администратору', accent: true),
            const SettingsAdminSection(),
          ],

          const SectionHeader('О приложении'),
          const SettingsAppSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CardsCountTile extends StatelessWidget {
  const _CardsCountTile();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardsViewModel>();
    final sync = context.watch<SyncService>();
    final theme = Theme.of(context);
    final busy = sync.state == SyncState.syncing;
    final failed = sync.state == SyncState.error;

    return ListTile(
      leading: const Icon(Icons.credit_card_outlined),
      title: Text('Всего карт: ${vm.cards.length}'),
      subtitle: const Text('Локальная база SQLite'),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : failed
          ? Icon(Icons.sync_problem, color: theme.colorScheme.error)
          : const Icon(Icons.check_circle_outline, color: Colors.green),
      onTap: () {
        if (sync.state != SyncState.error) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ошибка синхронизации'),
            content: Text(sync.lastError ?? 'Неизвестная ошибка'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await sync.sync();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      },
    );
  }
}
