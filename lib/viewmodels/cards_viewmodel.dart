import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/card_repository.dart';
import '../data/local/app_database.dart';

class CardsViewModel extends ChangeNotifier {
  CardsViewModel(this._repo) {
    _subscribe();
  }

  final CardRepository _repo;

  List<Cards> _cards = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  StreamSubscription<List<Cards>>? _sub;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;

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

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchVisibleCards().listen(
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
    super.dispose();
  }

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
}
