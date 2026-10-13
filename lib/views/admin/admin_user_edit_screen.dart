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
                if (_isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: const Text('Это вы'),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ReadonlyTile(
            icon: Icons.badge_outlined,
            title: 'Логин',
            subtitle: widget.user.login,
            hint: 'Логин нельзя изменить после создания',
          ),
          _ReadonlyTile(
            icon: Icons.person_outline,
            title: 'Имя',
            subtitle: widget.user.userName,
            hint: 'Сервер не поддерживает смену имени',
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
          if (_isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Нельзя менять свою роль',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Себя удалить нельзя. Выйдите из аккаунта и удалите '
                'себя с другой учётной записи администратора.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isAdmin ? 'Назначен администратором' : 'Снята роль администратора',
          ),
        ),
      );
      navigator.pop();
    } else {
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${admin.lastError ?? "неизвестно"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Новый пароль для ${widget.user.login}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrl,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  helperText: 'Минимум 6 символов',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите пароль';
                  if (v.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Повторите пароль',
                ),
                validator: (v) =>
                    (v != ctrl.text) ? 'Пароли не совпадают' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Сменить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      ctrl.dispose();
      confirmCtrl.dispose();
      return;
    }

    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await admin.changePassword(
      login: widget.user.login,
      password: ctrl.text,
    );
    ctrl.dispose();
    confirmCtrl.dispose();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Пароль обновлён' : 'Ошибка: ${admin.lastError ?? "неизвестно"}',
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить ${widget.user.login}?'),
        content: Text(
          'Пользователь «${widget.user.userName}» и все его права '
          'доступа к картам будут безвозвратно удалены.',
        ),
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

    final inputCtrl = TextEditingController();
    final doubleCheck = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Введите логин «${widget.user.login}» для подтверждения:'),
            const SizedBox(height: 12),
            TextField(
              controller: inputCtrl,
              autofocus: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.warning_amber_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              inputCtrl.text.trim() == widget.user.login,
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    inputCtrl.dispose();
    if (doubleCheck != true || !mounted) return;

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
        SnackBar(
          content: Text('Ошибка: ${admin.lastError ?? "неизвестно"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ReadonlyTile extends StatelessWidget {
  const _ReadonlyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.lock, size: 16),
    );
  }
}
