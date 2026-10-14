import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/barcode_utils.dart';
import '../local/app_database.dart';
import '../local/database_service.dart';
import '../models/sync_result.dart';
import '../remote/api_client.dart';
import '../remote/sync_api.dart';
import 'auth_service.dart';

enum SyncState { idle, syncing, error, done }

class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService({
    required DatabaseService dbService,
    required SyncApi api,
    required AuthService auth,
  }) : _dbService = dbService,
       _api = api,
       _auth = auth {
    _auth.addListener(_onAuthChanged);
  }

  final DatabaseService _dbService;
  final SyncApi _api;
  final AuthService _auth;

  AppDatabase get _db => _dbService.db;

  static const _debounce = Duration(seconds: 2);
  static const _pollInterval = Duration(minutes: 5);

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  bool _inProgress = false;

  DateTime? _lastFailureAt;
  bool _isBackground = false;
  bool _wasOnline = true;
  bool _started = false;

  StreamSubscription<List<Cards>>? _dirtySub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _debounceTimer;
  Timer? _pollTimer;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscribeToDirty();
    await _subscribeToConnectivity();
    _startPolling();
    if (_auth.isLoggedIn) scheduleSync();
  }

  @override
  void dispose() {
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _dirtySub?.cancel();
    _connSub?.cancel();
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
    if (_isBackground) {
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      _startPolling();
      if (_auth.isLoggedIn) scheduleSync();
    }
  }

  void scheduleSync() {
    if (!_started || !_auth.isLoggedIn) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final fail = _lastFailureAt;
      if (fail != null &&
          DateTime.now().difference(fail) < const Duration(seconds: 30)) {
        return;
      }
      sync();
    });
  }

  // ------------------------------------------------------------
  // Подписка на изменения локальной БД
  // ------------------------------------------------------------

  void _subscribeToDirty() {
    _dirtySub?.cancel();
    _dirtySub = _db.select(_db.cardsTable).watch().listen((_) async {
      final owner = _auth.username;
      if (!_auth.isLoggedIn || owner == null) return;

      final dirty =
          await (_db.select(_db.cardsTable)
                ..where(
                  (t) =>
                      t.ownerLogin.equals(owner) &
                      t.isDirty.equals(true) &
                      t.pendingDelete.equals(false),
                )
                ..limit(1))
              .getSingleOrNull();

      final del =
          await (_db.select(_db.cardsTable)
                ..where(
                  (t) =>
                      t.ownerLogin.equals(owner) & t.pendingDelete.equals(true),
                )
                ..limit(1))
              .getSingleOrNull();

      if (dirty == null && del == null) return;
      scheduleSync();
    });
  }

  Future<void> _subscribeToConnectivity() async {
    final conn = Connectivity();
    final initial = await conn.checkConnectivity();
    _wasOnline = !_isOffline(initial);
    _connSub = conn.onConnectivityChanged.listen((r) {
      final online = !_isOffline(r);
      if (online && !_wasOnline && _auth.isLoggedIn) scheduleSync();
      _wasOnline = online;
    });
  }

  bool _isOffline(List<ConnectivityResult> r) =>
      r.isEmpty || r.contains(ConnectivityResult.none);

  void _startPolling() {
    if (_isBackground || _pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_auth.isLoggedIn || _inProgress) return;
      sync();
    });
  }

  void _onAuthChanged() {
    if (_auth.isLoggedIn) {
      scheduleSync();
    } else {
      _debounceTimer?.cancel();
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  // ------------------------------------------------------------
  // Полный цикл
  // ------------------------------------------------------------

  Future<SyncResult> sync() async {
    if (_inProgress) return const SyncResult(pushed: 0, pulled: 0, deleted: 0);
    if (!_auth.isLoggedIn) {
      _lastError = 'Нужно войти в аккаунт для синхронизации';
      _state = SyncState.error;
      notifyListeners();
      return SyncResult(pushed: 0, pulled: 0, deleted: 0, error: _lastError);
    }

    _inProgress = true;
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final pushed = await _push();
      final deleted = await _pushDeletions();
      final pulled = await _pull();
      _lastSyncAt = DateTime.now();
      _lastFailureAt = null;
      _state = SyncState.done;
      return SyncResult(pushed: pushed, pulled: pulled, deleted: deleted);
    } on UnauthorizedException {
      _lastError = 'Сессия истекла. Войдите снова.';
      _state = SyncState.error;
      await _auth.handleUnauthorized();
      return SyncResult(pushed: 0, pulled: 0, deleted: 0, error: _lastError);
    } on DioException catch (e) {
      _lastFailureAt = DateTime.now();
      _lastError = _humanError(e);
      _state = SyncState.error;
      return SyncResult(pushed: 0, pulled: 0, deleted: 0, error: _lastError);
    } catch (e) {
      _lastFailureAt = DateTime.now();
      _lastError = 'Ошибка: $e';
      _state = SyncState.error;
      return SyncResult(pushed: 0, pulled: 0, deleted: 0, error: _lastError);
    } finally {
      _inProgress = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // PUSH — только карты текущего пользователя
  // ------------------------------------------------------------

  Future<int> _push() async {
    final owner = _auth.username;
    if (owner == null) return 0;

    final dirty =
        await (_db.select(_db.cardsTable)..where(
              (t) =>
                  t.ownerLogin.equals(owner) &
                  t.isDirty.equals(true) &
                  t.pendingDelete.equals(false),
            ))
            .get();
    if (dirty.isEmpty) return 0;

    var count = 0;
    for (final card in dirty) {
      try {
        if (card.serverId == null) {
          final created = await _api.createCard(
            name: card.name,
            barcode: card.barcode,
            about: card.about,
          );
          String? newId = created?.id;
          if (newId == null || newId.isEmpty) {
            final all = await _api.getCards();
            newId = all
                .where((c) => c.barcode == card.barcode)
                .map((c) => c.id)
                .firstOrNull;
          }
          if (newId != null && newId.isNotEmpty) {
            await _writeLocal(card, serverId: newId, dirty: false);
          }
        } else {
          final updated = await _api.updateCard(
            serverId: card.serverId!,
            name: card.name,
            barcode: card.barcode,
            about: card.about,
          );
          await _writeLocal(
            card,
            serverId: card.serverId,
            dirty: false,
            image: updated?.image,
          );
        }
        count++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await _hardDeleteLocal(card.id);
        } else {
          rethrow;
        }
      }
    }
    return count;
  }

  Future<int> _pushDeletions() async {
    final owner = _auth.username;
    if (owner == null) return 0;

    final toDelete =
        await (_db.select(_db.cardsTable)..where(
              (t) => t.ownerLogin.equals(owner) & t.pendingDelete.equals(true),
            ))
            .get();
    if (toDelete.isEmpty) return 0;

    var count = 0;
    for (final card in toDelete) {
      if (card.serverId == null) {
        await _hardDeleteLocal(card.id);
        count++;
        continue;
      }
      try {
        await _api.deleteCard(card.serverId!);
        await _hardDeleteLocal(card.id);
        count++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await _hardDeleteLocal(card.id);
          count++;
        } else {
          rethrow;
        }
      }
    }
    return count;
  }

  // ------------------------------------------------------------
  // PULL — карты с сервера, привязанные к текущему пользователю
  // ------------------------------------------------------------

  Future<int> _pull() async {
    final owner = _auth.username;
    if (owner == null) return 0;

    final remote = await _api.getCards();
    if (remote.isEmpty) return 0;

    var count = 0;
    for (final r in remote) {
      // 1. Ищем по serverId среди карт текущего владельца
      var local =
          await (_db.select(_db.cardsTable)..where(
                (t) => t.serverId.equals(r.id) & t.ownerLogin.equals(owner),
              ))
              .getSingleOrNull();

      // 2. Fallback по barcode среди карт текущего владельца
      if (local == null && r.barcode.isNotEmpty) {
        local =
            await (_db.select(_db.cardsTable)..where(
                  (t) =>
                      t.barcode.equals(r.barcode) & t.ownerLogin.equals(owner),
                ))
                .getSingleOrNull();
      }

      if (local == null) {
        await _db
            .into(_db.cardsTable)
            .insert(
              CardsTableCompanion.insert(
                serverId: Value(r.id),
                name: r.name,
                barcode: r.barcode,
                about: Value(r.about),
                image: Value(r.image),
                codeType: Value(guessCodeType(r.barcode)),
                ownerLogin: Value(owner),
                isDirty: const Value(false),
                pendingDelete: const Value(false),
              ),
            );
        count++;
      } else {
        final existing = local;
        if (existing.serverId == null) {
          await (_db.update(_db.cardsTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(CardsTableCompanion(serverId: Value(r.id)));
        }
        if (existing.isDirty || existing.pendingDelete) continue;

        final imageValue = r.image != null
            ? Value(r.image)
            : const Value<String?>.absent();

        await (_db.update(
          _db.cardsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          CardsTableCompanion(
            serverId: Value(r.id),
            name: Value(r.name),
            about: Value(r.about),
            barcode: Value(r.barcode),
            image: Value(r.image),
            updatedAt: Value(DateTime.now()),
          ),
        );
        count++;
      }
    }
    return count;
  }

  // ------------------------------------------------------------
  // Вспомогательные
  // ------------------------------------------------------------

  Future<void> _writeLocal(
    Cards card, {
    required String? serverId,
    required bool dirty,
    String? image,
  }) async {
    await (_db.update(
      _db.cardsTable,
    )..where((t) => t.id.equals(card.id))).write(
      CardsTableCompanion(
        serverId: Value(serverId),
        isDirty: Value(dirty),
        image: image != null ? Value(image) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _hardDeleteLocal(int id) async {
    await (_db.delete(_db.cardsTable)..where((t) => t.id.equals(id))).go();
  }

  String _humanError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Сервер не отвечает';
      case DioExceptionType.connectionError:
        return 'Не удалось подключиться к серверу';
      case DioExceptionType.badResponse:
        return 'Ошибка сервера: ${e.response?.statusCode}';
      default:
        return e.message ?? 'Ошибка сети';
    }
  }
}
