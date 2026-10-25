import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/data/local/database_service.dart';
import 'package:storcard_client/data/services/card_repository.dart';

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

  test('toggleFavorite меняет статус избранного в БД', () async {
    // 1. Создаем карту
    final id = await repo.createCard(
      name: 'Тест',
      barcode: '123',
      codeType: 'code128',
      ownerLogin: 'user1',
    );

    // 2. Проверяем, что по умолчанию не избранная
    var card = await repo.getById(id);
    expect(card!.isFavorite, false);

    // 3. Дергаем избранное
    await repo.toggleFavorite(id, true);
    card = await repo.getById(id);
    expect(card!.isFavorite, true);

    // 4. Убираем из избранного
    await repo.toggleFavorite(id, false);
    card = await repo.getById(id);
    expect(card!.isFavorite, false);
  });
}
