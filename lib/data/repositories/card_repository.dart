import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../local/database_service.dart';

class CardRepository {
  CardRepository(this._service);
  final DatabaseService _service;
  AppDatabase get _db => _service.db;

  Stream<List<Cards>> watchVisibleCards() {
    final q = _db.select(_db.cardsTable)
      ..where((t) => t.pendingDelete.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<Cards?> getById(int id) => (_db.select(
    _db.cardsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createCard({
    required String name,
    required String barcode,
    required String codeType,
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
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteCard(int id) async {
    await (_db.update(_db.cardsTable)..where((t) => t.id.equals(id))).write(
      CardsTableCompanion(
        pendingDelete: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
