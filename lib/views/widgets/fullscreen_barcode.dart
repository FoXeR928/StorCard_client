import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/barcode_utils.dart';
import '../../data/services/display_settings.dart';
import 'barcode_view.dart';

class FullscreenBarcode extends StatefulWidget {
  const FullscreenBarcode({
    super.key,
    required this.name,
    required this.barcode,
    required this.codeType,
    this.about,
  });

  final String name;
  final String barcode;
  final String codeType;
  final String? about;

  @override
  State<FullscreenBarcode> createState() => _FullscreenBarcodeState();
}

class _FullscreenBarcodeState extends State<FullscreenBarcode> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // 🔒 Блокируем поворот экрана (только портрет)
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _applyBrightness();
  }

  Future<void> _applyBrightness() async {
    final display = context.read<DisplaySettings>();
    try {
      if (display.mode == BrightnessMode.automatic) {
        final systemBrightness = await ScreenBrightness().system;
        final target = (systemBrightness + 0.3).clamp(0.1, 1.0);
        await ScreenBrightness().setScreenBrightness(target);
      } else {
        await ScreenBrightness().setScreenBrightness(display.manualBrightness);
      }
    } catch (_) {
      try {
        await ScreenBrightness().setScreenBrightness(1.0);
      } catch (_) {}
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    // 🔓 Возвращаем поворот при выходе с экрана
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _resetBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isQr = widget.codeType.toLowerCase() == 'qr';
    final size = MediaQuery.of(context).size;

    Widget barcodeContent;

    if (isQr) {
      // QR-код оставляем как есть (он квадратный, ему поворот не нужен)
      barcodeContent = SizedBox(
        width: size.width * 0.85,
        height: size.width * 0.85,
        child: BarcodeView(
          codeType: widget.codeType,
          data: widget.barcode,
          qrSize: size.width * 0.85,
        ),
      );
    } else {
      // 1D штрихкод принудительно разворачиваем на 90 градусов (вертикально)
      final longSide = size.height * 0.75; // Длина (отступы по краям)
      final shortSide = size.width * 0.6; // Высота

      barcodeContent = RotatedBox(
        quarterTurns: 1, // Поворот на 90 градусов
        child: SizedBox(
          width: longSide,
          height: shortSide,
          child: BarcodeView(
            codeType: widget.codeType,
            data: widget.barcode,
            width: longSide,
            barcodeHeight: shortSide,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(widget.name),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Center(child: barcodeContent)),
            Text(
              codeTypeLabel(widget.codeType),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.about?.isNotEmpty == true) ...[
              Text(
                widget.about!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.barcode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Clipboard.setData(ClipboardData(text: widget.barcode));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Код скопирован')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Скопировать код'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
