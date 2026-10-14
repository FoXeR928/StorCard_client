import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/dialogs.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/app_info_service.dart';
import '../../../data/services/auth_service.dart';

class SettingsAppSection extends StatelessWidget {
  const SettingsAppSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final info = AppInfoService.instance.cached;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Версия'),
          subtitle: Text(info?.versionFull ?? '—'),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(info?.appName ?? 'StorCard'),
          subtitle: Text(info?.description ?? 'Offline-first дисконтные карты'),
        ),
        const _ServerStatusTile(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LogoutButton(auth: auth),
        ),
      ],
    );
  }
}

class _ServerStatusTile extends StatelessWidget {
  const _ServerStatusTile();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    return ListTile(
      leading: admin.checkingServer
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              admin.serverStatus != null
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: admin.serverStatus != null ? Colors.green : Colors.grey,
            ),
      title: const Text('Сервер'),
      subtitle: Text(_subtitle(admin)),
      trailing: const Icon(Icons.refresh),
      onTap: admin.checkServerStatus,
    );
  }

  String _subtitle(AdminService admin) {
    if (admin.checkingServer) return 'Проверяем…';
    if (admin.serverStatus != null) return 'Доступен: ${admin.serverStatus}';
    if (admin.lastError != null) return 'Недоступен: ${admin.lastError}';
    return 'Нажмите, чтобы проверить';
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    if (!auth.isLoggedIn) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () async {
        final ok = await confirmDialog(
          context,
          title: 'Выйти из аккаунта?',
          content: 'Карты останутся на устройстве, но перестанут синхронизироваться.',
          confirmLabel: 'Выйти',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await context.read<AuthService>().logout();
        if (context.mounted) Navigator.pop(context);
      },
      icon: const Icon(Icons.logout),
      label: const Text('Выйти из аккаунта'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
