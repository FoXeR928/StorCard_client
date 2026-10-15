import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/dialogs.dart';
import '../data/local/app_database.dart';
import '../data/models/scan_result.dart';
import '../data/services/auth_service.dart';
import '../data/services/sync_service.dart';
import '../viewmodels/cards_viewmodel.dart';
import 'card_editor_screen.dart';
import 'card_view_screen.dart';
import 'scanner_screen.dart';
import 'widgets/account_sheet.dart';
import 'widgets/card_grid_tile.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  CardsViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm = context.read<CardsViewModel>();
      _vm!.addListener(_onVmChanged);
      _onVmChanged();
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    final vm = _vm;
    if (vm == null || !vm.shouldShowLocalCardsDialog) return;

    vm.markLocalCardsDialogShown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showLocalCardsDialog(vm.pendingLocalCardsCount);
    });
  }

  Future<void> _showLocalCardsDialog(int count) async {
    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Локальные карты'),
        content: Text(
          'Найдено $count карт, созданных без входа в аккаунт.\n\n'
          'Привязать их к текущему аккаунту? После синхронизации '
          'они станут доступны на всех ваших устройствах.\n\n'
          'Если оставить — они будут видны только в автономном '
          'режиме на этом устройстве.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Оставить локально'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Привязать'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    final vm = context.read<CardsViewModel>();
    if (choice == true) {
      await vm.assignLocalCardsToCurrentUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Карты привязаны к аккаунту')),
      );
    } else {
      vm.dismissLocalCardsDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardsViewModel>();
    final searching = vm.query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: context.read<CardsViewModel>().setQuery,
              )
            : const Text('Мои карты'),
        actions: [
          if (searching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.read<CardsViewModel>().setQuery(''),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Сканировать',
              onPressed: () => _scanAndCreate(context),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.read<CardsViewModel>().setQuery(' '),
            ),
            const AccountButton(),
          ],
        ],
        bottom: context.watch<SyncService>().state == SyncState.syncing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _Body(vm: vm),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        tooltip: 'Добавить карту',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CardEditorScreen()));
  }

  Future<void> _scanAndCreate(BuildContext context) async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(
          prefillBarcode: result.value,
          prefillCodeType: result.codeType,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});
  final CardsViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Ошибка: ${vm.error}', textAlign: TextAlign.center),
        ),
      );
    }
    if (vm.cards.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthService>();
        if (!auth.isLoggedIn) return;
        await context.read<SyncService>().sync();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: vm.cards.length,
        itemBuilder: (_, i) {
          final card = vm.cards[i];
          return CardGridTile(
            card: card,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CardViewScreen(cardId: card.id),
              ),
            ),
            onLongPress: () => _confirmDelete(context, card),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Cards card) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить карту?',
      content: 'Карта «${card.name}» будет удалена.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (ok && context.mounted) {
      await context.read<CardsViewModel>().deleteCard(card.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Пока нет ни одной карты', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Нажми «+», чтобы добавить первую карту',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final state = context.select<SyncService, SyncState>((s) => s.state);
    final busy = state == SyncState.syncing;

    return IconButton(
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              auth.isLoggedIn
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: auth.isLoggedIn
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
      tooltip: busy
          ? 'Синхронизация…'
          : (auth.isLoggedIn ? 'Синхронизировано' : 'Автономный режим'),
      onPressed: busy
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const AccountSheet(),
            ),
    );
  }
}
