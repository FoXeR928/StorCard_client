import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib_old/data/local/app_database.dart';
import '../../../lib_old/data/local/database_service.dart';
import '../../../lib_old/data/repositories/card_repository.dart';

void main() {
  late AppDatabase db;
  late CardRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.overrideForTest(db);
    repo = CardRepository(DatabaseService.instance);
  });

  tearDown(() async {
    await db.close();
    DatabaseService.instance.resetForTest();
  });

  group('createCard', () {
    test('creates card with isDirty=true', () async {
      final id = await repo.createCard(
        name: 'Магнит',
        barcode: '4600000000001',
        codeType: 'ean13',
      );

      expect(id, greaterThan(0));
      final card = await repo.getById(id);
      expect(card, isNotNull);
      expect(card!.name, 'Магнит');
      expect(card.barcode, '4600000000001');
      expect(card.codeType, 'ean13');
      expect(card.isDirty, isTrue);
      expect(card.pendingDelete, isFalse);
      expect(card.serverId, isNull);
    });

    test('creates multiple cards independently', () async {
      await repo.createCard(name: 'A', barcode: '1', codeType: 'code128');
      await repo.createCard(name: 'B', barcode: '2', codeType: 'code128');
      await repo.createCard(name: 'C', barcode: '3', codeType: 'code128');

      final all = await repo.getVisibleCards();
      expect(all.length, 3);
    });
  });

  group('getVisibleCards', () {
    test('sorts by name', () async {
      await repo.createCard(name: 'Яблоко', barcode: '1', codeType: 'code128');
      await repo.createCard(
        name: 'Апельсин',
        barcode: '2',
        codeType: 'code128',
      );
      await repo.createCard(name: 'Банан', barcode: '3', codeType: 'code128');

      final all = await repo.getVisibleCards();
      expect(all.map((c) => c.name).toList(), ['Апельсин', 'Банан', 'Яблоко']);
    });

    test('hides pendingDelete', () async {
      final id1 = await repo.createCard(
        name: 'Скрыть',
        barcode: '1',
        codeType: 'code128',
      );
      await repo.createCard(
        name: 'Оставить',
        barcode: '2',
        codeType: 'code128',
      );
      await repo.softDeleteCard(id1);

      final visible = await repo.getVisibleCards();
      expect(visible.length, 1);
      expect(visible.first.name, 'Оставить');
    });
  });

  group('watchVisibleCards', () {
    test('emits current list and reacts to changes', () async {
      final events = <List<Cards>>[];
      final sub = repo.watchVisibleCards().listen(events.add);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(events.isNotEmpty, isTrue);

      await repo.createCard(name: 'Test', barcode: '1', codeType: 'code128');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(events.last.length, 1);

      await sub.cancel();
    });
  });

  group('updateCard', () {
    test('updates fields and sets isDirty', () async {
      final id = await repo.createCard(
        name: 'Old',
        barcode: '111',
        codeType: 'code128',
      );
      final card = (await repo.getById(id))!;
      final updated = card.copyWith(name: 'New', barcode: '222');
      await repo.updateCard(updated);

      final after = (await repo.getById(id))!;
      expect(after.name, 'New');
      expect(after.barcode, '222');
      expect(after.isDirty, isTrue);
    });
  });

  group('softDeleteCard', () {
    test('sets pendingDelete', () async {
      final id = await repo.createCard(
        name: 'X',
        barcode: '1',
        codeType: 'code128',
      );
      await repo.softDeleteCard(id);

      final card = (await repo.getById(id))!;
      expect(card.pendingDelete, isTrue);
      expect(card.isDirty, isTrue);
    });
  });
}
