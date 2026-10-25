import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:storcard_client/data/services/backup_service.dart';

void main() {
  final service = BackupService.instance;
  const testPassword = 'my_super_secret_pass';

  test('Шифрование и расшифровка проходят успешно', () {
    final data = {
      'version': 2,
      'cards': [
        {'name': 'Test', 'barcode': '123'},
      ],
    };
    final jsonString = jsonEncode(data);

    // Шифруем
    final encryptedBytes = service.encryptToBytes(jsonString, testPassword);
    expect(encryptedBytes.isNotEmpty, true);

    // Расшифровываем
    final decryptedString = service.decryptFromBytes(
      encryptedBytes,
      testPassword,
    );

    expect(decryptedString, isNotNull);
    expect(jsonDecode(decryptedString!), equals(data));
  });

  test('Расшифровка с неверным паролем возвращает null', () {
    final data = {'foo': 'bar'};
    final encryptedBytes = service.encryptToBytes(
      jsonEncode(data),
      testPassword,
    );

    // Пробуем неверный пароль
    final decryptedString = service.decryptFromBytes(
      encryptedBytes,
      'wrong_password',
    );

    expect(decryptedString, isNull);
  });

  test('Расшифровка поврежденного файла возвращает null', () {
    final badBytes = [1, 2, 3]; // Меньше 16 байт
    final decryptedString = service.decryptFromBytes(badBytes, testPassword);

    expect(decryptedString, isNull);
  });
}
