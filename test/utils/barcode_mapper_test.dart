import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib_old/utils/barcode_mapper.dart';

void main() {
  group('mapCodeType', () {
    test('ean13 returns Barcode', () {
      expect(mapCodeType('ean13'), isA<Barcode>());
    });

    test('qr returns Barcode', () {
      expect(mapCodeType('qr'), isA<Barcode>());
    });

    test('case-insensitive', () {
      expect(
        mapCodeType('EAN13').runtimeType,
        mapCodeType('ean13').runtimeType,
      );
      expect(mapCodeType('QR').runtimeType, mapCodeType('qr').runtimeType);
    });

    test('unknown → fallback', () {
      expect(mapCodeType('gibberish'), isA<Barcode>());
    });

    test('all known types', () {
      const types = [
        'ean13',
        'ean8',
        'code128',
        'code39',
        'code93',
        'upca',
        'upce',
        'itf',
        'qr',
        'datamatrix',
        'pdf417',
      ];
      for (final t in types) {
        expect(mapCodeType(t), isA<Barcode>(), reason: 'type=$t');
      }
    });
  });

  group('codeTypeLabel', () {
    test('known types', () {
      expect(codeTypeLabel('ean13'), 'EAN-13');
      expect(codeTypeLabel('ean8'), 'EAN-8');
      expect(codeTypeLabel('code128'), 'Code-128');
      expect(codeTypeLabel('qr'), 'QR-код');
      expect(codeTypeLabel('datamatrix'), 'DataMatrix');
    });

    test('case-insensitive', () {
      expect(codeTypeLabel('QR'), 'QR-код');
      expect(codeTypeLabel('EAN13'), 'EAN-13');
    });

    test('unknown → upper-case', () {
      expect(codeTypeLabel('unknown'), 'UNKNOWN');
    });
  });
}
