import 'package:barcode_widget/barcode_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode;

/// Строка → объект Barcode для отрисовки.
Barcode barcodeFromCodeType(String codeType) {
  switch (codeType.toLowerCase()) {
    case 'ean13':
      return Barcode.ean13();
    case 'ean8':
      return Barcode.ean8();
    case 'code39':
      return Barcode.code39();
    case 'code93':
      return Barcode.code93();
    case 'upca':
      return Barcode.upcA();
    case 'upce':
      return Barcode.upcE();
    case 'itf':
      return Barcode.itf();
    case 'qr':
      return Barcode.qrCode();
    case 'datamatrix':
      return Barcode.dataMatrix();
    case 'pdf417':
      return Barcode.pdf417();
    case 'code128':
    default:
      return Barcode.code128();
  }
}

/// Человеко-читаемое название типа.
String codeTypeLabel(String codeType) {
  const map = {
    'ean13': 'EAN-13',
    'ean8': 'EAN-8',
    'code128': 'Code-128',
    'code39': 'Code-39',
    'code93': 'Code-93',
    'upca': 'UPC-A',
    'upce': 'UPC-E',
    'itf': 'ITF',
    'qr': 'QR-код',
    'datamatrix': 'DataMatrix',
    'pdf417': 'PDF417',
  };
  return map[codeType.toLowerCase()] ?? codeType.toUpperCase();
}

/// Формат сканера → наш codeType.
String? codeTypeFromScannerFormat(BarcodeFormat? format) {
  if (format == null) return null;
  switch (format) {
    case BarcodeFormat.ean13:
      return 'ean13';
    case BarcodeFormat.ean8:
      return 'ean8';
    case BarcodeFormat.code128:
      return 'code128';
    case BarcodeFormat.code39:
      return 'code39';
    case BarcodeFormat.code93:
      return 'code93';
    case BarcodeFormat.upcA:
      return 'upca';
    case BarcodeFormat.upcE:
      return 'upce';
    case BarcodeFormat.itf:
      return 'itf';
    case BarcodeFormat.qrCode:
      return 'qr';
    case BarcodeFormat.dataMatrix:
      return 'datamatrix';
    case BarcodeFormat.pdf417:
      return 'pdf417';
    default:
      return 'code128';
  }
}

/// Грубая догадка типа по виду строки (сервер не отдаёт codeType).
String guessCodeType(String barcode) {
  if (RegExp(r'^\d{13}$').hasMatch(barcode)) return 'ean13';
  if (RegExp(r'^\d{8}$').hasMatch(barcode)) return 'ean8';
  if (barcode.startsWith('http') || barcode.length > 60) return 'qr';
  return 'code128';
}
