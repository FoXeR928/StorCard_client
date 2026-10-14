import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../data/repositories/card_repository.dart';
import '../data/services/auth_service.dart';

class CardsViewModel extends ChangeNotifier {
  CardsViewModel(this._repo, this._auth) {
    _auth.addListener(_onAuthChanged);
    _subscribe();
  }

  final CardRepository _repo;
  final AuthService _auth;

  List<Cards> _cards = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _pendingLocalCardsCount = 0;

  String? _localCardsDialogShownFor;

  StreamSubscription<List<Cards>>? _sub;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  int get pendingLocalCardsCount => _pendingLocalCardsCount;

  bool get shouldShowLocalCardsDialog =>
      _pendingLocalCardsCount > 0 &&
      _auth.username != _localCardsDialogShownFor;

  List<Cards> get cards {
    if (_query.isEmpty) return _cards;
    final q = _query.toLowerCase();
    return _cards.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.barcode.toLowerCase().contains(q) ||
          (c.about?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void _onAuthChanged() {
    if (_auth.username != _localCardsDialogShownFor) {
      _localCardsDialogShownFor = null;
    }
    // Пользователь сменился (или вышел) — пересоздаём подписку.
    _subscribe();
    // И проверяем, есть ли локальные карты для миграции.
    checkLocalCardsAfterLogin();
  }

  void _subscribe() {
    _sub?.cancel();
    final owner = _auth.username; // null если offline
    _sub = _repo
        .watchVisibleCards(owner)
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

  // ---------- CRUD ----------

  Future<void> addCard({
    required String name,
    required String barcode,
    required String codeType,
    String? about,
    String? image,
  }) async {
    try {
      await _repo.createCard(
        name: name,
        barcode: barcode,
        codeType: codeType,
        ownerLogin: _auth.username,
        about: about,
        image: image,
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

  // ---------- Миграция локальных карт ----------

  Future<void> checkLocalCardsAfterLogin() async {
    if (_auth.username == null) {
      _pendingLocalCardsCount = 0;
      return;
    }
    final count = await _repo.countLocalOnlyCards();
    _pendingLocalCardsCount = count;
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

  /// Пометить, что диалог про локальные карты уже показан
  /// текущему пользователю. Вызывается из UI перед показом.
  void markLocalCardsDialogShown() {
    _localCardsDialogShownFor = _auth.username;
    notifyListeners();
  }

  /// Пользователь нажал «Оставить локально» — больше не навязываемся
  /// в рамках этой сессии.
  void dismissLocalCardsDialog() {
    _pendingLocalCardsCount = 0;
    _localCardsDialogShownFor = _auth.username;
    notifyListeners();
  }
}
