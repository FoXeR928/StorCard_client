import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipientDirectory extends ChangeNotifier {
  static const _kKey = 'share_recipients';
  static const _max = 30;

  List<String> _recent = [];
  List<String> get recent => List.unmodifiable(_recent);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _recent = p.getStringList(_kKey) ?? [];
    notifyListeners();
  }

  Future<void> remember(String login) async {
    final t = login.trim();
    if (t.isEmpty) return;
    _recent.remove(t);
    _recent.insert(0, t);
    if (_recent.length > _max) _recent = _recent.sublist(0, _max);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, _recent);
    notifyListeners();
  }

  Future<void> forget(String login) async {
    _recent.remove(login);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kKey, _recent);
    notifyListeners();
  }
}
