import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import '../settings/settings_screen.dart';

class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: auth.isLoggedIn
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    auth.isLoggedIn ? Icons.person : Icons.person_off_outlined,
                    color: auth.isLoggedIn
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isLoggedIn ? auth.username! : 'Автономный режим',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.isLoggedIn
                            ? auth.serverUrl!
                            : 'Данные хранятся только на этом устройстве',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (auth.isLoggedIn) ...[
              _SyncButton(),
              _LastSyncLabel(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthService>().logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
            ] else
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthService>().requireLogin();
                },
                icon: const Icon(Icons.login),
                label: const Text('Войти в аккаунт'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Настройки'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final busy = sync.state == SyncState.syncing;

    return FilledButton.icon(
      onPressed: busy ? null : () => _runSync(context, sync),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      label: Text(busy ? 'Синхронизация…' : 'Синхронизировать'),
    );
  }

  Future<void> _runSync(BuildContext context, SyncService sync) async {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    Navigator.pop(context);

    final result = await sync.sync();
    if (!context.mounted) return;

    if (result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Синхронизировано: ↑${result.pushed} ↓${result.pulled} 🗑${result.deleted}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Ошибка синхронизации'),
          backgroundColor: scheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _LastSyncLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.watch<SyncService>().lastSyncAt;
    if (t == null) return const SizedBox.shrink();
    final text =
        'Обновлено ${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
