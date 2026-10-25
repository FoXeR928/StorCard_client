import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../core/utils/barcode_utils.dart';

class BarcodeView extends StatelessWidget {
  const BarcodeView({
    super.key,
    required this.codeType,
    required this.data,
    this.qrSize = 240,
    this.barcodeHeight = 120,
    this.width, // <-- ДОБАВЛЕНО
  });

  final String codeType;
  final String data;
  final double qrSize;
  final double barcodeHeight;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isQr = codeType.toLowerCase() == 'qr';
    return BarcodeWidget(
      barcode: barcodeFromCodeType(codeType),
      data: data,
      width: width ?? (isQr ? qrSize : double.infinity),
      height: isQr ? qrSize : barcodeHeight,
      drawText: false,
      errorBuilder: (context, error) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              'Не удалось отрисовать код',
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
