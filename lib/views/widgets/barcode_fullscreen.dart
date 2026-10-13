import 'package:flutter/material.dart';

import 'barcode_view.dart';

class BarcodeFullScreen extends StatelessWidget {
  const BarcodeFullScreen({
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: BarcodeView(codeType: codeType, data: barcode),
            ),
            const SizedBox(height: 12),
            Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (about?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(about!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
