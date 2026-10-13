import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/server_user.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/auth_service.dart';
import 'admin_user_edit_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final myLogin = context.read<AuthService>().username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: admin.loadingUsers ? null : admin.loadUsers,
          ),
        ],
      ),
      body: _body(admin, myLogin),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _body(AdminService admin, String? myLogin) {
    if (admin.loadingUsers && admin.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (admin.lastError != null && admin.users.isEmpty) {
      return _ErrorState(message: admin.lastError!, onRetry: admin.loadUsers);
    }
    if (admin.users.isEmpty) {
      return const Center(child: Text('Нет пользователей'));
    }

    return RefreshIndicator(
      onRefresh: admin.loadUsers,
      child: ListView.separated(
        itemCount: admin.users.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final user = admin.users[i];
          return _UserTile(user: user, isMe: user.login == myLogin);
        },
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _CreateUserDialogScreen()));
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.isMe});
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Ошибка: $message', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог создания пользователя, вынесенный в отдельный виджет.
class _CreateUserDialogScreen extends StatefulWidget {
  const _CreateUserDialogScreen();

  @override
  State<_CreateUserDialogScreen> createState() =>
      _CreateUserDialogScreenState();
}

class _CreateUserDialogScreenState extends State<_CreateUserDialogScreen> {
  final _loginCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdmin = false;
  bool _obscure = true;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await admin.registerUser(
      login: _loginCtrl.text.trim(),
      userName: _nameCtrl.text.trim(),
      password: _passCtrl.text,
      isAdmin: _isAdmin,
    );

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Пользователь создан${_isAdmin ? " (админ)" : ""}'
              : 'Ошибка: ${admin.lastError ?? "неизвестно"}',
        ),
        backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пользователь')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _loginCtrl,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Логин',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Укажи логин';
                if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v.trim())) {
                  return 'Только буквы, цифры, . _ -';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Имя',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Укажи имя' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                helperText: 'Минимум 6 символов',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Укажи пароль';
                if (v.length < 6) return 'Минимум 6 символов';
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.shield_outlined),
              title: const Text('Администратор'),
              subtitle: const Text('Сразу выдать права'),
              value: _isAdmin,
              onChanged: (v) => setState(() => _isAdmin = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}
