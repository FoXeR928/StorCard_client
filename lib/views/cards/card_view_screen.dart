import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/dialogs.dart';
import '../../data/services/auth_service.dart';
import '../../viewmodels/cards_viewmodel.dart';
import '../widgets/card_code_view.dart';
import '../widgets/card_image_view.dart';
import '../widgets/fullscreen_barcode.dart';
import '../widgets/share_sheet.dart';
import 'card_editor_screen.dart';

class CardViewScreen extends StatefulWidget {
  const CardViewScreen({super.key, required this.cardId});
  final int cardId;

  @override
  State<CardViewScreen> createState() => _CardViewScreenState();
}

class _CardViewScreenState extends State<CardViewScreen> {
  PageController? _pageCtrl;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsViewModel>().cards;
    if (cards.isEmpty)
      return const Scaffold(body: Center(child: Text('Нет карт')));

    var initialIndex = cards.indexWhere((c) => c.id == widget.cardId);
    if (initialIndex < 0) initialIndex = 0;
    _pageCtrl ??= PageController(initialPage: initialIndex);

    return PageView.builder(
      controller: _pageCtrl,
      itemCount: cards.length,
      itemBuilder: (_, i) => _CardPage(cardId: cards[i].id),
    );
  }
}

class _CardPage extends StatelessWidget {
  const _CardPage({required this.cardId});
  final int cardId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardsViewModel>();
    final card = vm.cards.firstWhere((c) => c.id == cardId);
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Поделиться',
            onPressed: () => _openShareSheet(context, card.serverId, card.name),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CardEditorScreen(cardId: card.id),
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Удалить с сервера (Админ)',
              onPressed: () => _adminHardDelete(context, card.serverId),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenBarcode(
                      name: card.name,
                      barcode: card.barcode,
                      codeType: card.codeType,
                    ),
                  ),
                ),
                child: CardCodeView(
                  barcode: card.barcode,
                  codeType: card.codeType,
                ),
              ),
              const SizedBox(height: 20),
              if (card.image?.isNotEmpty == true) ...[
                CardImageView(raw: card.image!),
                const SizedBox(height: 16),
              ],
              if (card.about?.isNotEmpty == true) ...[
                Text(
                  card.about!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyCode(context, card.barcode),
                      icon: const Icon(Icons.copy),
                      label: const Text('Копировать'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _changeImage(context, card.serverId),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        card.image?.isEmpty ?? true ? 'Фото' : 'Заменить',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Код скопирован'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openShareSheet(
    BuildContext context,
    String? serverId,
    String cardName,
  ) {
    if (serverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала синхронизируйте карту с сервером'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ShareSheet(serverId: serverId, cardName: cardName),
    );
  }

  Future<void> _adminHardDelete(BuildContext context, String? serverId) async {
    if (serverId == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Полное удаление?',
      content: 'Карта будет стёрта с сервера для всех пользователей.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    final error = await context.read<CardsViewModel>().adminHardDelete(
      serverId,
    );
    if (!context.mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _changeImage(BuildContext context, String? serverId) async {
    if (serverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала синхронизируйте карту')),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final vm = context.read<CardsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (xfile == null) return;
    final file = File(xfile.path);

    messenger.showSnackBar(const SnackBar(content: Text('Загрузка картинки…')));
    final error = await vm.uploadImage(serverId, file);
    messenger.hideCurrentSnackBar();

    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Картинка обновлена')),
      );
    }
  }
}
