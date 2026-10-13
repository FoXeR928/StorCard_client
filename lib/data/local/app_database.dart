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
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get pendingDelete =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CardsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
