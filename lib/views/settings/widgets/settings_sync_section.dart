import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/admin_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/sync_service.dart';

class SettingsSyncSection extends StatelessWidget {
  const SettingsSyncSection({
    super.key,
    required this.sync,
    required this.auth,
  });

  final SyncService sync;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final busy = sync.state == SyncState.syncing;
    final last = sync.lastSyncAt;

    return Column(
      children: [
        ListTile(
          leading: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_sync_outlined),
          title: Text(busy ? 'Синхронизация…' : 'Состояние'),
          subtitle: Text(_subtitle(last)),
          trailing: auth.isLoggedIn
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: busy ? null : () => sync.sync(),
                )
              : null,
        ),
        if (auth.isLoggedIn && !auth.isAdmin) const _CheckRoleTile(),
      ],
    );
  }

  String _subtitle(DateTime? last) {
    if (!auth.isLoggedIn) return 'Войдите в аккаунт для синхронизации';
    if (last == null) return 'Ещё не синхронизировалось';
    final hh = last.hour.toString().padLeft(2, '0');
    final mm = last.minute.toString().padLeft(2, '0');
    return 'Обновлено в $hh:$mm';
  }
}

class _CheckRoleTile extends StatelessWidget {
  const _CheckRoleTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.verified_user_outlined),
      title: const Text('Проверить права администратора'),
      subtitle: const Text('Если вы админ, но раздел не появился'),
      onTap: () async {
        final auth = context.read<AuthService>();
        final admin = context.read<AdminService>();
        final messenger = ScaffoldMessenger.of(context);
        await admin.checkRole();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              auth.isAdmin
                  ? 'Права администратора подтверждены'
                  : 'Права администратора не обнаружены',
            ),
          ),
        );
      },
    );
  }
}
