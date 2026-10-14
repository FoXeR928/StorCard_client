import 'package:flutter_test/flutter_test.dart';
import 'package:storcard_client/data/models/auth_result.dart';
import 'package:storcard_client/data/models/scan_result.dart';
import 'package:storcard_client/data/models/server_admin_card.dart';
import 'package:storcard_client/data/models/server_card.dart';
import 'package:storcard_client/data/models/server_user.dart';
import 'package:storcard_client/data/models/sync_result.dart';

void main() {
  group('ServerCard', () {
    test('полный JSON', () {
      final c = ServerCard.fromJson({
        'id': 'abc-123',
        'name': 'Пятёрочка',
        'barcode': '1234567890',
        'about': 'Скидка 5%',
        'image': 'media/card1.jpg',
      });
      expect(c.id, 'abc-123');
      expect(c.name, 'Пятёрочка');
      expect(c.barcode, '1234567890');
      expect(c.about, 'Скидка 5%');
      expect(c.image, 'media/card1.jpg');
      expect(c.isEmpty, false);
    });

    test('альтернативные ключи (card_id, uuid)', () {
      final c = ServerCard.fromJson({'card_id': 'x'});
      expect(c.id, 'x');

      final c2 = ServerCard.fromJson({'uuid': 'y'});
      expect(c2.id, 'y');
    });

    test('пустой JSON → isEmpty', () {
      final c = ServerCard.fromJson({});
      expect(c.id, '');
      expect(c.name, '');
      expect(c.barcode, '');
      expect(c.isEmpty, true);
    });

    test('числа приводятся к строке', () {
      final c = ServerCard.fromJson({'id': 42, 'name': 'X', 'barcode': 100});
      expect(c.id, '42');
      expect(c.barcode, '100');
    });

    test('null-поля не падают', () {
      final c = ServerCard.fromJson({
        'id': 'a',
        'name': null,
        'barcode': null,
        'about': null,
        'image': null,
      });
      expect(c.name, '');
      expect(c.barcode, '');
      expect(c.about, isNull);
    });
  });

  group('ServerUser', () {
    test('стандартные ключи', () {
      final u = ServerUser.fromJson({
        'login': 'admin',
        'user_name': 'Админ',
        'is_admin': true,
      });
      expect(u.login, 'admin');
      expect(u.userName, 'Админ');
      expect(u.isAdmin, true);
    });

    test('fallback на username / name', () {
      final u = ServerUser.fromJson({'username': 'x', 'name': 'Икс'});
      expect(u.login, 'x');
      expect(u.userName, 'Икс');
    });

    test('user_name падает на login если нет', () {
      final u = ServerUser.fromJson({'login': 'bob'});
      expect(u.userName, 'bob');
    });

    test('is_admin как строка "true"? → false (строгая проверка)', () {
      final u = ServerUser.fromJson({'login': 'x', 'is_admin': 'true'});
      expect(u.isAdmin, false);
    });
  });

  group('ServerAdminCard', () {
    test('owner_login парсится', () {
      final c = ServerAdminCard.fromJson({
        'id': '1',
        'name': 'A',
        'barcode': '1',
        'owner_login': 'user1',
      });
      expect(c.ownerLogin, 'user1');
    });

    test('альтернативные ключи owner', () {
      expect(ServerAdminCard.fromJson({'owner': 'u1'}).ownerLogin, 'u1');
      expect(ServerAdminCard.fromJson({'login': 'u2'}).ownerLogin, 'u2');
    });
  });

  group('AuthResult', () {
    test('success', () {
      final r = AuthResult.success();
      expect(r.isSuccess, true);
      expect(r.error, isNull);
    });

    test('failure', () {
      final r = AuthResult.failure('ошибка');
      expect(r.isSuccess, false);
      expect(r.error, 'ошибка');
    });
  });

  group('SyncResult', () {
    test('isSuccess если error == null', () {
      const r = SyncResult(pushed: 1, pulled: 2, deleted: 3);
      expect(r.isSuccess, true);
    });

    test('isFailure при error', () {
      const r = SyncResult(pushed: 0, pulled: 0, deleted: 0, error: 'x');
      expect(r.isSuccess, false);
      expect(r.error, 'x');
    });
  });

  group('ScanResult', () {
    test('хранит value и codeType', () {
      const r = ScanResult(value: '123', codeType: 'ean13');
      expect(r.value, '123');
      expect(r.codeType, 'ean13');
    });
  });
}
