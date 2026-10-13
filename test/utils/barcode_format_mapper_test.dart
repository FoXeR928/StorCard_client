import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../lib_old/utils/barcode_format_mapper.dart';

void main() {
  group('mapScannedFormat', () {
    test('null → null', () {
      expect(mapScannedFormat(null), isNull);
    });

    test('EAN-13', () {
      expect(mapScannedFormat(BarcodeFormat.ean13), 'ean13');
    });

    test('EAN-8', () {
      expect(mapScannedFormat(BarcodeFormat.ean8), 'ean8');
    });

    test('Code-128', () {
      expect(mapScannedFormat(BarcodeFormat.code128), 'code128');
    });

    test('QR', () {
      expect(mapScannedFormat(BarcodeFormat.qrCode), 'qr');
    });

    test('DataMatrix', () {
      expect(mapScannedFormat(BarcodeFormat.dataMatrix), 'datamatrix');
    });

    test('unknown → code128 fallback', () {
      expect(mapScannedFormat(BarcodeFormat.unknown), 'code128');
    });
  });
}
