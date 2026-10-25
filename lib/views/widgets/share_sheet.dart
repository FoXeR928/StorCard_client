import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/admin_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/recipient_directory.dart';
import '../../data/services/sharing_service.dart';
import '../../data/services/sync_service.dart';
import '../../viewmodels/share_viewmodel.dart';

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.serverId, required this.cardName});
  final String serverId;
  final String cardName;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _loginCtrl = TextEditingController();
  final _focusNode = FocusNode();
  ShareViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= ShareViewModel(
      auth: context.read<AuthService>(),
      admin: context.read<AdminService>(),
      sharing: context.read<SharingService>(),
      directory: context.read<RecipientDirectory>(),
    )..loadDirectory();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _focusNode.dispose();
    _vm?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final err = await _vm!.share(
      serverId: widget.serverId,
      targetLogin: _loginCtrl.text,
    );
    if (!mounted || err != null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Доступ выдан: ${_loginCtrl.text.trim()}')),
    );
    await context.read<SyncService>().sync();
  }

  Future<void> _transferOwnership() async {
    final login = _loginCtrl.text.trim();
    if (login.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Передать владение?'),
        content: Text(
          'Карта «${widget.cardName}» станет собственностью $login. Вы потеряете права владельца.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Передать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err = await _vm!.transferOwnership(
      serverId: widget.serverId,
      targetLogin: login,
    );
    if (!mounted || err != null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Владение передано: $login')));
    await context.read<SyncService>().sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = _vm!;
    final candidates = vm.candidates();

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Поделиться «${widget.cardName}»',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (candidates.isNotEmpty)
              _AutocompleteField(
                controller: _loginCtrl,
                focusNode: _focusNode,
                candidates: candidates,
                isRecent: vm.isRecent,
                loadingUsers: vm.loadingUsers,
                onRefresh: vm.refreshDirectory,
              )
            else
              TextField(
                controller: _loginCtrl,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Логин пользователя',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.loadingUsers ? null : vm.refreshDirectory,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'viewer',
                  label: Text('Просмотр'),
                  icon: Icon(Icons.visibility_outlined),
                ),
                ButtonSegment(
                  value: 'editor',
                  label: Text('Редактирование'),
                  icon: Icon(Icons.edit_outlined),
                ),
              ],
              selected: {vm.accessLevel},
              onSelectionChanged: (s) => vm.setAccessLevel(s.first),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: vm.busy ? null : _share,
              icon: vm.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: const Text('Выдать доступ'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: vm.busy ? null : _transferOwnership,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Передать владение'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.candidates,
    required this.isRecent,
    required this.loadingUsers,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> candidates;
  final bool Function(String) isRecent;
  final bool loadingUsers;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return candidates;
        return candidates.where((c) => c.toLowerCase().contains(q));
      },
      onSelected: (v) {
        controller.text = v;
        controller.selection = TextSelection.collapsed(offset: v.length);
      },
      fieldViewBuilder: (_, ctrl, fn, _) => TextField(
        controller: ctrl,
        focusNode: fn,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'Логин пользователя',
          hintText: 'Начните вводить или выберите из списка',
          prefixIcon: const Icon(Icons.person_outline),
          suffixIcon: IconButton(
            tooltip: 'Обновить список',
            icon: loadingUsers
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: loadingUsers ? null : onRefresh,
          ),
        ),
      ),
      optionsViewBuilder: (ctx, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isRecent(opt) ? Icons.history : Icons.person_outline,
                    size: 20,
                  ),
                  title: Text(opt),
                  onTap: () => onSelected(opt),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
