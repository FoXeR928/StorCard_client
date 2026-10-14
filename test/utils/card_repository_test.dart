import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/data/local/database_service.dart';
import 'package:storcard_client/data/repositories/card_repository.dart';

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
  });

  group('createCard', () {
    test('сохраняет owner login', () async {
      await repo.createCard(
        name: 'A',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'user1',
      );

      final cards = await repo.watchVisibleCards('user1').first;
      expect(cards.length, 1);
      expect(cards.first.name, 'A');
      expect(cards.first.ownerLogin, 'user1');
      expect(cards.first.isDirty, true);
      expect(cards.first.pendingDelete, false);
    });

    test('ownerLogin=null сохраняется', () async {
      await repo.createCard(
        name: 'L',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );

      final offline = await repo.watchVisibleCards(null).first;
      expect(offline.length, 1);
      expect(offline.first.ownerLogin, isNull);
    });
  });

  group('watchVisibleCards', () {
    test('фильтрует по владельцу', () async {
      await repo.createCard(
        name: 'A',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'user1',
      );
      await repo.createCard(
        name: 'B',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: 'user2',
      );

      final u1 = await repo.watchVisibleCards('user1').first;
      expect(u1.map((c) => c.name), ['A']);

      final u2 = await repo.watchVisibleCards('user2').first;
      expect(u2.map((c) => c.name), ['B']);
    });

    test('ownerLogin=null → только offline-карты', () async {
      await repo.createCard(
        name: 'Offline',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.createCard(
        name: 'User1',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: 'user1',
      );

      final offline = await repo.watchVisibleCards(null).first;
      expect(offline.map((c) => c.name), ['Offline']);
    });

    test('сортирует по имени', () async {
      await repo.createCard(
        name: 'C',
        barcode: '3',
        codeType: 'code128',
        ownerLogin: 'u',
      );
      await repo.createCard(
        name: 'A',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'u',
      );
      await repo.createCard(
        name: 'B',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: 'u',
      );

      final cards = await repo.watchVisibleCards('u').first;
      expect(cards.map((c) => c.name), ['A', 'B', 'C']);
    });

    test('pendingDelete карты не видны', () async {
      final id = await repo.createCard(
        name: 'X',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'u',
      );
      await repo.softDeleteCard(id);

      final visible = await repo.watchVisibleCards('u').first;
      expect(visible, isEmpty);
    });
  });

  group('countLocalOnlyCards', () {
    test('считает только карты без владельца', () async {
      await repo.createCard(
        name: 'L1',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.createCard(
        name: 'L2',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.createCard(
        name: 'U',
        barcode: '3',
        codeType: 'code128',
        ownerLogin: 'user1',
      );

      expect(await repo.countLocalOnlyCards(), 2);
    });

    test('pendingDelete не учитывается', () async {
      final id = await repo.createCard(
        name: 'L',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.softDeleteCard(id);

      expect(await repo.countLocalOnlyCards(), 0);
    });

    test('возвращает 0 если карт нет', () async {
      expect(await repo.countLocalOnlyCards(), 0);
    });
  });

  group('assignLocalCardsTo', () {
    test('прикрепляет локальные карты к пользователю', () async {
      await repo.createCard(
        name: 'L1',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.createCard(
        name: 'L2',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: null,
      );

      final n = await repo.assignLocalCardsTo('user1');
      expect(n, 2);
      expect(await repo.countLocalOnlyCards(), 0);

      final userCards = await repo.watchVisibleCards('user1').first;
      expect(userCards.length, 2);
    });

    test('не трогает карты других пользователей', () async {
      await repo.createCard(
        name: 'Other',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'other',
      );
      await repo.createCard(
        name: 'L',
        barcode: '2',
        codeType: 'code128',
        ownerLogin: null,
      );

      await repo.assignLocalCardsTo('user1');

      final other = await repo.watchVisibleCards('other').first;
      expect(other.length, 1);
      expect(other.first.name, 'Other');
    });

    test('ставит isDirty=true для синхронизации', () async {
      await repo.createCard(
        name: 'L',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: null,
      );
      await repo.assignLocalCardsTo('user1');

      final cards = await repo.watchVisibleCards('user1').first;
      expect(cards.first.isDirty, true);
    });
  });

  group('updateCard', () {
    test('обновляет поля и ставит isDirty', () async {
      final id = await repo.createCard(
        name: 'Old',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'u',
      );

      await repo.updateCard(
        id,
        name: 'New',
        barcode: '2',
        codeType: 'ean13',
        about: 'note',
      );

      final card = await repo.getById(id);
      expect(card!.name, 'New');
      expect(card.barcode, '2');
      expect(card.codeType, 'ean13');
      expect(card.about, 'note');
      expect(card.isDirty, true);
    });
  });

  group('softDeleteCard', () {
    test('ставит pendingDelete=true и isDirty=true', () async {
      final id = await repo.createCard(
        name: 'X',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'u',
      );

      await repo.softDeleteCard(id);

      final card = await repo.getById(id);
      expect(card, isNotNull);
      expect(card!.pendingDelete, true);
      expect(card.isDirty, true);
    });

    test('карта остаётся в БД (soft delete)', () async {
      final id = await repo.createCard(
        name: 'X',
        barcode: '1',
        codeType: 'code128',
        ownerLogin: 'u',
      );
      await repo.softDeleteCard(id);

      final all = await db.select(db.cardsTable).get();
      expect(all.length, 1);
    });
  });

  group('getById', () {
    test('возвращает null для несуществующей карты', () async {
      expect(await repo.getById(999), isNull);
    });
  });
}
