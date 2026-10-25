import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/dialogs.dart';
import '../../data/local/app_database.dart';
import '../../viewmodels/cards_viewmodel.dart';
import '../../data/models/scan_result.dart';
import 'scanner_screen.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({
    super.key,
    this.cardId,
    this.prefillBarcode,
    this.prefillCodeType,
  });

  final int? cardId;
  final String? prefillBarcode;
  final String? prefillCodeType;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();

  String _codeType = 'code128';
  bool _isEdit = false;
  Cards? _existing;

  static const _codeTypes = [
    ('ean13', 'EAN-13'),
    ('ean8', 'EAN-8'),
    ('code128', 'Code-128'),
    ('code39', 'Code-39'),
    ('qr', 'QR-код'),
    ('datamatrix', 'DataMatrix'),
    ('text', 'Просто текст'),
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.cardId != null;
    if (_isEdit) {
      final cards = context.read<CardsViewModel>().cards;
      _existing = cards.firstWhere((c) => c.id == widget.cardId);
      _nameCtrl.text = _existing!.name;
      _codeCtrl.text = _existing!.barcode;
      _aboutCtrl.text = _existing!.about ?? '';
      _codeType = _existing!.codeType;
    } else {
      if (widget.prefillBarcode != null) {
        _codeCtrl.text = widget.prefillBarcode!;
      }
      if (widget.prefillCodeType != null) _codeType = widget.prefillCodeType!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать карту' : 'Новая карта'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Название магазина'),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Укажи название';
                if (v.trim().length > 100) return 'Максимум 100 символов';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: 'Номер карты / штрихкод',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Сканировать',
                  onPressed: _scan,
                ),
              ),
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Укажи код';
                if (v.trim().length > 100) return 'Максимум 100 символов';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _codeType,
              decoration: const InputDecoration(labelText: 'Тип кода'),
              items: [
                for (final (value, label) in _codeTypes)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (v) => setState(() => _codeType = v ?? 'code128'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutCtrl,
              decoration: const InputDecoration(
                labelText: 'Заметка (необязательно)',
              ),
              maxLines: 3,
              maxLength: 255,
              validator: (v) {
                if (v != null && v.length > 255) {
                  return 'Максимум 255 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<CardsViewModel>();
    final about = _aboutCtrl.text.trim();

    if (_isEdit && _existing != null) {
      await vm.updateCard(
        id: _existing!.id,
        name: _nameCtrl.text.trim(),
        barcode: _codeCtrl.text.trim(),
        codeType: _codeType,
        about: about.isEmpty ? null : about,
      );
    } else {
      await vm.addCard(
        name: _nameCtrl.text.trim(),
        barcode: _codeCtrl.text.trim(),
        codeType: _codeType,
        about: about.isEmpty ? null : about,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _codeCtrl.text = result.value;
      _codeType = result.codeType;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Считано: ${result.value} (${result.codeType})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить карту?',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<CardsViewModel>().deleteCard(_existing!.id);
    if (mounted) Navigator.of(context).pop();
  }
}
