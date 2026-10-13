import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/server_admin_card.dart';
import '../../data/remote/api_client.dart';
import '../../data/services/admin_service.dart';
import '../widgets/barcode_fullscreen.dart';

class AdminAllCardsScreen extends StatefulWidget {
  const AdminAllCardsScreen({super.key});

  @override
  State<AdminAllCardsScreen> createState() => _AdminAllCardsScreenState();
}

class _AdminAllCardsScreenState extends State<AdminAllCardsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadAllCards();
    });
  }

  List<ServerAdminCard> _filter(List<ServerAdminCard> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.barcode.toLowerCase().contains(q) ||
          (c.ownerLogin?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminService>();
    final filtered = _filter(admin.allCards);

    return Scaffold(
      appBar: AppBar(
        title: _query.isEmpty
            ? const Text('Все карты')
            : TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _query = ''),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _query = ' '),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: admin.loadingCards ? null : admin.loadAllCards,
            ),
          ],
        ],
      ),
      body: _body(admin, filtered),
    );
  }

  Widget _body(AdminService admin, List<ServerAdminCard> filtered) {
    if (admin.loadingCards && admin.allCards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (admin.lastError != null && admin.allCards.isEmpty) {
      return _ErrorState(
        message: admin.lastError!,
        onRetry: admin.loadAllCards,
      );
    }
    if (filtered.isEmpty) return const Center(child: Text('Ничего не найдено'));

    return RefreshIndicator(
      onRefresh: admin.loadAllCards,
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) => _CardTile(card: filtered[i]),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});
  final ServerAdminCard card;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(card.name.isNotEmpty ? card.name[0].toUpperCase() : '?'),
      ),
      title: Text(card.name),
      subtitle: Text(
        card.ownerLogin == null
            ? card.barcode
            : '${card.ownerLogin} • ${card.barcode}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showDetail(context),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _onAction(context, v),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.qr_code_2),
              title: Text('Показать код'),
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: ListTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Поделиться'),
            ),
          ),
          PopupMenuItem(
            value: 'owner',
            child: ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text('Передать владение'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    switch (action) {
      case 'view':
        _showDetail(context);
        break;
      case 'share':
        _openShareSheet(context, isOwnerTransfer: false);
        break;
      case 'owner':
        _openShareSheet(context, isOwnerTransfer: true);
        break;
      case 'delete':
        await _confirmDelete(context);
        break;
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BarcodeFullScreen(
        name: card.name,
        barcode: card.barcode,
        codeType: 'code128',
        about: card.about,
      ),
    );
  }

  void _openShareSheet(BuildContext context, {required bool isOwnerTransfer}) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isOwnerTransfer
                  ? 'Передать владение «${card.name}»'
                  : 'Поделиться «${card.name}»',
              style: Theme.of(sheetCtx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Логин получателя',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  _submitShare(sheetCtx, ctrl.text.trim(), isOwnerTransfer),
              icon: Icon(isOwnerTransfer ? Icons.swap_horiz : Icons.share),
              label: Text(isOwnerTransfer ? 'Передать' : 'Выдать доступ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitShare(
    BuildContext context,
    String login,
    bool isOwnerTransfer,
  ) async {
    if (login.isEmpty) return;
    final apiClient = context.read<ApiClient>();
    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (isOwnerTransfer) {
        await apiClient.client.put(
          '/cards/${card.id}/owner',
          data: {'target_login': login},
        );
      } else {
        await apiClient.client.post(
          '/cards/${card.id}/share',
          data: {'target_login': login, 'access_level': 'viewer'},
        );
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOwnerTransfer
                ? 'Владение передано: $login'
                : 'Доступ выдан: $login',
          ),
        ),
      );
      await admin.loadAllCards();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Удалить «${card.name}»?'),
        content: Text(
          'Карта будет удалена у владельца'
          '${card.ownerLogin != null ? " (${card.ownerLogin})" : ""}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final apiClient = context.read<ApiClient>();
    final admin = context.read<AdminService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await apiClient.client.delete('/cards/${card.id}');
      messenger.showSnackBar(const SnackBar(content: Text('Карта удалена')));
      await admin.loadAllCards();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
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
