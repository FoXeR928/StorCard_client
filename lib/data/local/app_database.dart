import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('Cards')
class CardsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
  TextColumn get barcode => text()();
  TextColumn get image => text().nullable()();
  TextColumn get codeType => text().withDefault(const Constant('code128'))();

  /// Логин владельца. null = карта создана в offline-режиме, ещё никому не принадлежит.
  TextColumn get ownerLogin => text().nullable()();

  /// Реальный владелец на сервере (приходит с бэкенда)
  TextColumn get serverOwnerLogin => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get pendingDelete =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [CardsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(cardsTable, cardsTable.ownerLogin);
      }
      if (from < 3) {
        await m.addColumn(cardsTable, cardsTable.isFavorite);
      }
      if (from < 4) {
        await m.addColumn(cardsTable, cardsTable.serverOwnerLogin);
      }
    },
  );
}
