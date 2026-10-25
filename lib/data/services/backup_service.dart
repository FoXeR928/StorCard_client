import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Шифрует строку в байты.
  /// Формат файла: [16 байт IV] + [Зашифрованный текст]
  Uint8List encryptToBytes(String data, String password) {
    // Ключ — это SHA-256 хеш от пароля (32 байта для AES-256)
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));

    // Вектор инициализации
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  /// Расшифровывает байты в строку (возвращает null, если пароль неверный)
  String? decryptFromBytes(List<int> fileBytes, String password) {
    try {
      if (fileBytes.length < 16) throw Exception('Файл поврежден');

      final ivBytes = fileBytes.sublist(0, 16);
      final encryptedBytes = fileBytes.sublist(16);

      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(ivBytes));
      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null; // Неверный пароль или битый файл
    }
  }

  /// Создает зашифрованный файл и открывает окно "Поделиться"
  Future<bool> exportToFile({
    required Map<String, dynamic> data,
    required String password,
    required String filenamePrefix,
  }) async {
    try {
      final bytes = encryptToBytes(jsonEncode(data), password);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${filenamePrefix}_$timestamp.storcard');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], subject: 'StorCard Backup');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> decryptFromFile({
    required List<int> fileBytes,
    required String password,
  }) async {
    return decryptFromBytes(fileBytes, password);
  }
}
