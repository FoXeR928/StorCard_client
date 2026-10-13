import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'app_database.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  AppDatabase? _db;

  AppDatabase get db =>
      _db ?? (throw StateError('БД не инициализирована. Вызови init()'));

  Future<void> init() async {
    if (_db != null) return;
    _db = AppDatabase(driftDatabase(name: 'cards_db'));
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @visibleForTesting
  void overrideForTest(AppDatabase db) => _db = db;
}
