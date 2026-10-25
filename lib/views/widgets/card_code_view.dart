import 'package:flutter/material.dart';

import '../../core/utils/barcode_utils.dart';
import 'barcode_view.dart';

class CardCodeView extends StatelessWidget {
  const CardCodeView({
    super.key,
    required this.barcode,
    required this.codeType,
  });
  final String barcode;
  final String codeType;

  @override
  Widget build(BuildContext context) {
    final isQr = codeType.toLowerCase() == 'qr';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          BarcodeView(
            codeType: codeType,
            data: barcode,
            qrSize: isQr ? MediaQuery.of(context).size.width * 0.7 : 240,
            barcodeHeight: 160,
          ),
          const SizedBox(height: 24),
          Text(
            codeTypeLabel(codeType),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            barcode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
