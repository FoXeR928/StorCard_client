import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/dialogs.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/recipient_directory.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    if (!auth.isLoggedIn) {
      return ListTile(
        leading: const Icon(Icons.person_off_outlined),
        title: const Text('Автономный режим'),
        subtitle: const Text('Данные хранятся только на этом устройстве'),
        trailing: FilledButton.tonal(
          onPressed: () async {
            await context.read<AuthService>().requireLogin();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Войти'),
        ),
      );
    }

    return Column(
      children: [
        _UserTile(auth: auth),
        _ChangePasswordTile(auth: auth),
        _ChangeServerTile(auth: auth),
        const _RecentRecipientsTile(),
      ],
    );
  }
}

// ---------- Плитка пользователя ----------

class _UserTile extends StatelessWidget {
  const _UserTile({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(auth.username ?? '—'),
      subtitle: Text(auth.serverUrl ?? '—'),
      trailing: auth.isAdmin
          ? Chip(
              label: const Text('Админ'),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
            )
          : null,
    );
  }
}

// ---------- Смена пароля ----------

class _ChangePasswordTile extends StatelessWidget {
  const _ChangePasswordTile({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: const Text('Сменить пароль'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _changePassword(context),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final password = await promptDialog(
      context,
      title: 'Сменить пароль',
      label: 'Новый пароль',
      obscure: true,
      validator: (v) =>
          (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
    );
    if (password == null || !context.mounted) return;

    final admin = context.read<AdminService>();
    final ok = await admin.changePassword(
      login: auth.username!,
      password: password,
    );
    if (!context.mounted) return;
    showSnack(
      context,
      ok ? 'Пароль изменён' : 'Ошибка: ${admin.lastError}',
      error: !ok,
    );
  }
}

// ---------- Смена сервера ----------

class _ChangeServerTile extends StatelessWidget {
  const _ChangeServerTile({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dns_outlined),
      title: const Text('Сменить сервер'),
      subtitle: Text(auth.serverUrl ?? '—'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _changeServer(context),
    );
  }

  Future<void> _changeServer(BuildContext context) async {
    final url = await promptDialog(
      context,
      title: 'Адрес сервера',
      label: 'URL',
      hint: 'http://192.168.1.100:8000',
      initial: auth.serverUrl,
      keyboardType: TextInputType.url,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Укажи адрес';
        final uri = Uri.tryParse(v.trim());
        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          return 'Должно начинаться с http:// или https://';
        }
        return null;
      },
    );
    if (url == null || !context.mounted) return;

    await context.read<AuthService>().rememberServerUrl(url);
    if (!context.mounted) return;
    showSnack(context, 'Адрес сохранён. Войдите заново.');
    await context.read<AuthService>().logout();
    if (context.mounted) Navigator.pop(context);
  }
}

// ---------- Недавние получатели ----------

class _RecentRecipientsTile extends StatelessWidget {
  const _RecentRecipientsTile();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipientDirectory>(
      builder: (context, dir, _) {
        if (dir.recent.isEmpty) return const SizedBox.shrink();
        return ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Недавние получатели'),
          subtitle: Text('${dir.recent.length} логинов сохранено'),
          trailing: TextButton(
            onPressed: () => _clear(context, dir),
            child: const Text('Очистить'),
          ),
        );
      },
    );
  }

  Future<void> _clear(BuildContext context, RecipientDirectory dir) async {
    final ok = await confirmDialog(
      context,
      title: 'Очистить список?',
      content: 'Последние получатели будут удалены из подсказок.',
      confirmLabel: 'Очистить',
      destructive: true,
    );
    if (!ok) return;
    for (final l in List<String>.from(dir.recent)) {
      await dir.forget(l);
    }
  }
}
