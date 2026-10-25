import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/data/local/database_service.dart';
import 'package:storcard_client/data/models/server_card.dart';
import 'package:storcard_client/data/remote/card_api.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/data/services/sync_service.dart';

class MockCardApi extends Mock implements CardApi {}

class MockAuth extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockCardApi api;
  late MockAuth auth;
  late SyncService sync;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseService.instance.overrideForTest(db);
    api = MockCardApi();
    auth = MockAuth();

    when(() => auth.isLoggedIn).thenReturn(true);
    when(() => auth.username).thenReturn('user1');
    when(() => auth.addListener(any())).thenReturn(null);
    when(() => auth.removeListener(any())).thenReturn(null);

    sync = SyncService(
      dbService: DatabaseService.instance,
      api: api,
      auth: auth,
    );
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test('_push отправляет новую карту на сервер и сохраняет serverId', () async {
    // 1. Создаем "грязную" (несинхронизированную) карту локально
    await db
        .into(db.cardsTable)
        .insert(
          CardsTableCompanion.insert(
            name: 'Пятерочка',
            barcode: '12345',
            ownerLogin: const Value('user1'),
            isDirty: const Value(true),
          ),
        );

    // 2. Мокаем ответы API
    when(() => api.createCard(name: 'Пятерочка', barcode: '12345', about: null))
        .thenAnswer(
          (_) async => const ServerCard(
            id: 'srv-id-999',
            name: 'Пятерочка',
            barcode: '12345',
          ),
        );
    when(() => api.getCards()).thenAnswer((_) async => []);

    // 3. Запускаем синхронизацию
    final result = await sync.sync();

    // 4. Проверяем результат
    expect(result.isSuccess, true);
    expect(result.pushed, 1);

    // Проверяем, что карта стала "чистой" и получила ID от сервера
    final localCard = await db.select(db.cardsTable).getSingle();
    expect(localCard.isDirty, false);
    expect(localCard.serverId, 'srv-id-999');
  });

  test('_push удаляет локальную карту, если сервер вернул 404', () async {
    // 1. Создаем карту, которая якобы уже есть на сервере, но её там удалили
    await db
        .into(db.cardsTable)
        .insert(
          CardsTableCompanion.insert(
            name: 'Удаленная',
            barcode: '000',
            serverId: const Value('missing-srv-id'),
            ownerLogin: const Value('user1'),
            isDirty: const Value(true),
          ),
        );

    // 2. Сервер отвечает 404 (Not Found)
    when(
      () => api.updateCard(
        serverId: 'missing-srv-id',
        name: 'Удаленная',
        barcode: '000',
        about: null,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/cards/missing-srv-id'),
        response: Response(
          requestOptions: RequestOptions(path: '/cards/missing-srv-id'),
          statusCode: 404,
        ),
      ),
    );

    // 3. Запускаем синхронизацию
    await sync.sync();

    // 4. Проверяем, что локальная карта исчезла (так как её нет на сервере)
    final count = await db.select(db.cardsTable).get();
    expect(count, isEmpty);
  });
}
