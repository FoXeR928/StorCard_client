import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../local/database_service.dart';

class CardRepository {
  CardRepository(this._service);
  final DatabaseService _service;
  AppDatabase get _db => _service.db;

  /// Стрим карт, принадлежащих конкретному юзеру.
  /// Если ownerLogin == null, отдаёт локальные карты (офлайн-режим).
  Stream<List<Cards>> watchVisibleCards(String? ownerLogin) {
    final q = _db.select(_db.cardsTable)
      ..where((t) => t.pendingDelete.equals(false));

    if (ownerLogin == null) {
      q.where((t) => t.ownerLogin.isNull());
    } else {
      q.where((t) => t.ownerLogin.equals(ownerLogin));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<Cards?> getById(int id) => (_db.select(
    _db.cardsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createCard({
    required String name,
    required String barcode,
    required String codeType,
    required String? ownerLogin,
    String? about,
    String? image,
  }) {
    return _db
        .into(_db.cardsTable)
        .insert(
          CardsTableCompanion.insert(
            name: name,
            barcode: barcode,
            codeType: Value(codeType),
            about: Value(about),
            image: Value(image),
            ownerLogin: Value(ownerLogin),
            isDirty: const Value(true),
            pendingDelete: const Value(false),
          ),
        );
  }

  Future<void> updateCard(
    int id, {
    required String name,
    required String barcode,
    required String codeType,
    String? about,
    String? image,
  }) async {
    await (_db.update(_db.cardsTable)..where((t) => t.id.equals(id))).write(
      CardsTableCompanion(
        name: Value(name),
        barcode: Value(barcode),
        codeType: Value(codeType),
        about: Value(about),
        image: Value(image),
        isDirty: const Value(true), // Помечаем для синхронизации
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Мягкое удаление — карта исчезает из UI, но остается в БД с флагом pendingDelete.
  Future<void> softDeleteCard(int id) async {
    await (_db.update(_db.cardsTable)..where((t) => t.id.equals(id))).write(
      CardsTableCompanion(
        pendingDelete: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Считает карты, созданные до входа в аккаунт.
  Future<int> countLocalOnlyCards() async {
    final q = _db.selectOnly(_db.cardsTable)
      ..addColumns([_db.cardsTable.id.count()])
      ..where(
        _db.cardsTable.ownerLogin.isNull() &
            _db.cardsTable.pendingDelete.equals(false),
      );
    final row = await q.getSingle();
    return row.read(_db.cardsTable.id.count()) ?? 0;
  }

  /// Привязывает все офлайн-карты к текущему юзеру при входе.
  Future<int> assignLocalCardsTo(String ownerLogin) async {
    return (_db.update(_db.cardsTable)
          ..where((t) => t.ownerLogin.isNull() & t.pendingDelete.equals(false)))
        .write(
          CardsTableCompanion(
            ownerLogin: Value(ownerLogin),
            isDirty: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Переключает статус "Избранное".
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await (_db.update(_db.cardsTable)..where((t) => t.id.equals(id))).write(
      CardsTableCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
