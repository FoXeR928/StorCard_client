import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/server_user.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/auth_service.dart';

class AdminUserEditScreen extends StatefulWidget {
  const AdminUserEditScreen({super.key, required this.user});
  final ServerUser user;

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  late bool _isAdmin = widget.user.isAdmin;
  bool _busy = false;
  bool _dirty = false;

  bool get _isMe => context.read<AuthService>().username == widget.user.login;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователь'),
        actions: [
          TextButton(
            onPressed: (!_dirty || _busy) ? null : _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _isAdmin
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    _isAdmin ? Icons.shield : Icons.person,
                    size: 40,
                    color: _isAdmin
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.user.userName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  widget.user.login,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Логин'),
            subtitle: Text(widget.user.login),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Имя'),
            subtitle: Text(widget.user.userName),
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(_isAdmin ? Icons.shield : Icons.person_outline),
            title: const Text('Администратор'),
            subtitle: Text(
              _isAdmin
                  ? 'Полный доступ: пользователи, все карты'
                  : 'Обычный пользователь: только свои карты',
            ),
            value: _isAdmin,
            onChanged: (_isMe || _busy)
                ? null
                : (v) => setState(() {
                    _isAdmin = v;
                    _dirty = true;
                  }),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Сменить пароль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _changePassword,
          ),
          const SizedBox(height: 24),
          if (!_isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Удалить пользователя'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_dirty || _busy) return;
    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _busy = true);
    final ok = await admin.setRole(widget.user.login, _isAdmin);
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Роль обновлена')));
      navigator.pop();
    } else {
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка: ${admin.lastError}')),
      );
    }
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Новый пароль для ${widget.user.login}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Новый пароль'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сменить'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctrl.text.isNotEmpty && mounted) {
      final admin = context.read<AdminService>();
      final messenger = ScaffoldMessenger.of(context);
      final ok = await admin.changePassword(
        login: widget.user.login,
        password: ctrl.text,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Пароль обновлён' : 'Ошибка: ${admin.lastError}',
            ),
          ),
        );
      }
    }
    ctrl.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить ${widget.user.login}?'),
        content: const Text('Все данные пользователя будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await admin.deleteUser(widget.user.login);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Пользователь удалён')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка: ${admin.lastError}')),
      );
    }
  }
}
