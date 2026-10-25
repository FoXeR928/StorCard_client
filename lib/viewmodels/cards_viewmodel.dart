import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../data/remote/api_client.dart';
import '../data/services/card_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/backup_service.dart';
import '../data/services/image_service.dart';
import '../data/services/sync_service.dart';

enum CardSort { favoriteFirst, nameAsc, nameDesc, newest }

class CardsViewModel extends ChangeNotifier {
  CardsViewModel(
    this._repo,
    this._auth,
    this._imageService,
    this._apiClient,
    this._syncService,
  ) {
    _auth.addListener(_onAuthChanged);
    _subscribe();
  }

  final CardRepository _repo;
  final AuthService _auth;
  final ImageService _imageService;
  final ApiClient _apiClient;
  final SyncService _syncService;

  // --- Состояние ---
  List<Cards> _cards = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  CardSort _sort = CardSort.favoriteFirst;
  int _pendingLocalCardsCount = 0;
  String? _localCardsDialogShownFor;

  StreamSubscription<List<Cards>>? _sub;

  // --- Геттеры ---
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  CardSort get sort => _sort;
  int get pendingLocalCardsCount => _pendingLocalCardsCount;

  /// Показывать ли диалог «Привязать локальные карты?» при входе.
  bool get shouldShowLocalCardsDialog =>
      _pendingLocalCardsCount > 0 &&
      _auth.username != _localCardsDialogShownFor;

  /// Список карт с учетом поиска и сортировки.
  List<Cards> get cards {
    // 1. Фильтрация по поиску
    var list = _query.isEmpty
        ? List<Cards>.from(_cards)
        : _cards.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.barcode.toLowerCase().contains(q) ||
                (c.about?.toLowerCase().contains(q) ?? false);
          }).toList();

    // 2. Сортировка
    switch (_sort) {
      case CardSort.favoriteFirst:
        list.sort((a, b) {
          if (a.isFavorite == b.isFavorite) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return a.isFavorite ? -1 : 1;
        });
        break;
      case CardSort.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case CardSort.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case CardSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setSort(CardSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --- Слушатели и стримы ---

  void _onAuthChanged() {
    if (_auth.username != _localCardsDialogShownFor) {
      _localCardsDialogShownFor = null; // Сбрасываем при смене юзера
    }
    _subscribe();
    checkLocalCardsAfterLogin();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo
        .watchVisibleCards(_auth.username)
        .listen(
          (list) {
            _cards = list;
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  // --- CRUD (Создание, Чтение, Обновление, Удаление) ---

  Future<void> addCard({
    required String name,
    required String barcode,
    required String codeType,
    String? about,
  }) async {
    try {
      await _repo.createCard(
        name: name,
        barcode: barcode,
        codeType: codeType,
        ownerLogin: _auth.username,
        about: about,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCard({
    required int id,
    required String name,
    required String barcode,
    required String codeType,
    String? about,
  }) async {
    try {
      await _repo.updateCard(
        id,
        name: name,
        barcode: barcode,
        codeType: codeType,
        about: about,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCard(int id) async {
    try {
      await _repo.softDeleteCard(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int id, bool isFav) async {
    try {
      await _repo.toggleFavorite(id, isFav);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // --- Действия с сервером (загрузка фото, админское удаление) ---

  /// Загружает картинку и сразу делает синхронизацию, чтобы обновить пути.
  /// Возвращает null при успехе или текст ошибки.
  Future<String?> uploadImage(String serverId, File file) async {
    try {
      final result = await _imageService.upload(serverId: serverId, file: file);
      if (result != null &&
          !result.startsWith('Ошибка') &&
          !result.startsWith('Недостаточно')) {
        await _syncService.sync(); // Скачиваем новые пути к картинкам
        return null;
      }
      return result;
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  /// Полное удаление карты с сервера (только для админа).
  Future<String?> adminHardDelete(String serverId) async {
    try {
      await _apiClient.client.delete('/cards/$serverId');
      await _syncService.sync();
      return null;
    } catch (e) {
      return 'Ошибка удаления: $e';
    }
  }

  // --- Экспорт / Импорт ---

  /// Экспорт карт в зашифрованный файл.
  Future<String?> exportToFile(String password) async {
    try {
      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'cards': _cards
            .map(
              (c) => {
                'name': c.name,
                'barcode': c.barcode,
                'about': c.about,
                'codeType': c.codeType,
              },
            )
            .toList(),
      };

      final ok = await BackupService.instance.exportToFile(
        data: data,
        password: password,
        filenamePrefix: 'cards_export',
      );
      return ok ? null : 'Не удалось создать файл';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  /// Импорт карт из JSON-строки (используется в диалоге вставки).
  Future<int> importFromJson(String jsonString) async {
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      int count = 0;
      for (final item in data) {
        await _repo.createCard(
          name: item['name'] ?? 'Без названия',
          barcode: item['barcode'] ?? '',
          codeType: item['codeType'] ?? 'code128',
          ownerLogin: _auth.username,
          about: item['about'],
        );
        count++;
      }
      return count;
    } catch (e) {
      _error = 'Ошибка импорта: $e';
      notifyListeners();
      return 0;
    }
  }

  // --- Миграция локальных карт (созданных до входа) ---

  Future<void> checkLocalCardsAfterLogin() async {
    if (_auth.username == null) {
      _pendingLocalCardsCount = 0;
      return;
    }
    _pendingLocalCardsCount = await _repo.countLocalOnlyCards();
    notifyListeners();
  }

  Future<void> assignLocalCardsToCurrentUser() async {
    final user = _auth.username;
    if (user == null) return;
    await _repo.assignLocalCardsTo(user);
    _pendingLocalCardsCount = 0;
    _localCardsDialogShownFor = user;
    notifyListeners();
  }

  void markLocalCardsDialogShown() {
    _localCardsDialogShownFor = _auth.username;
    notifyListeners();
  }

  void dismissLocalCardsDialog() {
    _pendingLocalCardsCount = 0;
    _localCardsDialogShownFor = _auth.username;
    notifyListeners();
  }
}
