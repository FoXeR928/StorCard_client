import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/utils/barcode_utils.dart';
import '../data/services/image_service.dart';
import '../data/services/sync_service.dart';
import '../viewmodels/cards_viewmodel.dart';
import 'card_editor_screen.dart';
import 'widgets/barcode_view.dart';
import 'widgets/card_image.dart';
import 'widgets/share_sheet.dart';

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
    ScreenBrightness().setScreenBrightness(1.0);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    ScreenBrightness().resetScreenBrightness();
    _pageCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsViewModel>().cards;
    if (cards.isEmpty) {
      return const Scaffold(body: Center(child: Text('Нет карт')));
    }
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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (card.image?.isNotEmpty == true) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CardImage(raw: card.image!),
                  ),
                  const SizedBox(height: 16),
                ],
                _CodeCard(barcode: card.barcode, codeType: card.codeType),
                if (card.about?.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  Text(
                    card.about!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _copyCode(context, card.barcode),
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать код'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _changeImage(context, card.serverId),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    card.image?.isEmpty ?? true
                        ? 'Добавить картинку'
                        : 'Заменить картинку',
                  ),
                ),
              ],
            ),
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

  String _name(BuildContext context) {
    final vm = context.read<CardsViewModel>();
    return vm.cards.firstWhere((c) => c.id == cardId).name;
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

    final imageService = context.read<ImageService>();
    final sync = context.read<SyncService>();
    final messenger = ScaffoldMessenger.of(context);

    final File? file = source == ImageSource.gallery
        ? await imageService.pickFromGallery()
        : await imageService.takePhoto();
    if (file == null) return;

    messenger.showSnackBar(const SnackBar(content: Text('Загрузка картинки…')));
    final result = await imageService.upload(serverId: serverId, file: file);
    messenger.hideCurrentSnackBar();

    if (result == null ||
        result.startsWith('Ошибка') ||
        result.startsWith('Недостаточно') ||
        result.startsWith('Карта не')) {
      messenger.showSnackBar(
        SnackBar(content: Text(result ?? 'Неизвестная ошибка')),
      );
      return;
    }

    await sync.sync();
    messenger.showSnackBar(const SnackBar(content: Text('Картинка обновлена')));
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.barcode, required this.codeType});
  final String barcode;
  final String codeType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          BarcodeView(codeType: codeType, data: barcode),
          const SizedBox(height: 20),
          Text(
            codeTypeLabel(codeType),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            barcode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
