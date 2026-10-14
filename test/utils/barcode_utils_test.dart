import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode;
import 'package:storcard_client/core/utils/barcode_utils.dart';

void main() {
  group('codeTypeLabel', () {
    test('возвращает читаемые метки', () {
      expect(codeTypeLabel('ean13'), 'EAN-13');
      expect(codeTypeLabel('ean8'), 'EAN-8');
      expect(codeTypeLabel('code128'), 'Code-128');
      expect(codeTypeLabel('qr'), 'QR-код');
      expect(codeTypeLabel('datamatrix'), 'DataMatrix');
    });

    test('регистр не важен', () {
      expect(codeTypeLabel('CODE128'), 'Code-128');
      expect(codeTypeLabel('QR'), 'QR-код');
    });

    test('неизвестный тип → uppercase', () {
      expect(codeTypeLabel('xyz'), 'XYZ');
    });
  });

  group('guessCodeType', () {
    test('13 цифр → ean13', () {
      expect(guessCodeType('1234567890123'), 'ean13');
    });

    test('8 цифр → ean8', () {
      expect(guessCodeType('12345678'), 'ean8');
    });

    test('короткое число → code128', () {
      expect(guessCodeType('1234'), 'code128');
    });

    test('URL → qr', () {
      expect(guessCodeType('https://example.com'), 'qr');
    });

    test('очень длинная строка → qr', () {
      expect(guessCodeType('A' * 70), 'qr');
    });
  });

  group('barcodeFromCodeType', () {
    test('возвращает Barcode для известных типов', () {
      expect(barcodeFromCodeType('qr'), isA<Barcode>());
      expect(barcodeFromCodeType('ean13'), isA<Barcode>());
      expect(barcodeFromCodeType('code128'), isA<Barcode>());
    });

    test('неизвестный тип → code128 (fallback)', () {
      expect(barcodeFromCodeType('xyz'), isA<Barcode>());
    });
  });

  group('codeTypeFromScannerFormat', () {
    test('null → null', () {
      expect(codeTypeFromScannerFormat(null), isNull);
    });

    test('ean13 / qr / code128 мапятся', () {
      expect(codeTypeFromScannerFormat(BarcodeFormat.ean13), 'ean13');
      expect(codeTypeFromScannerFormat(BarcodeFormat.qrCode), 'qr');
      expect(codeTypeFromScannerFormat(BarcodeFormat.code128), 'code128');
      expect(codeTypeFromScannerFormat(BarcodeFormat.dataMatrix), 'datamatrix');
    });

    test('все поддерживаемые форматы', () {
      const formats = [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf,
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
      ];
      for (final f in formats) {
        expect(codeTypeFromScannerFormat(f), isNotNull, reason: '$f');
      }
    });
  });
}
