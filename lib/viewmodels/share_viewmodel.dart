import 'package:flutter/foundation.dart';

import '../data/services/admin_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/recipient_directory.dart';
import '../data/services/sharing_service.dart';

class ShareViewModel extends ChangeNotifier {
  ShareViewModel({
    required AuthService auth,
    required AdminService admin,
    required SharingService sharing,
    required RecipientDirectory directory,
  }) : _auth = auth,
       _admin = admin,
       _sharing = sharing,
       _directory = directory;

  final AuthService _auth;
  final AdminService _admin;
  final SharingService _sharing;
  final RecipientDirectory _directory;

  String _accessLevel = 'viewer';
  bool _busy = false;
  bool _loadingUsers = false;
  String? _error;

  String get accessLevel => _accessLevel;
  bool get busy => _busy;
  bool get loadingUsers => _loadingUsers;
  String? get error => _error;

  /// Список логинов для автодополнения: недавние + все пользователи сервера.
  List<String> candidates() {
    final set = <String>{..._directory.recent};
    set.addAll(_admin.users.map((u) => u.login));
    set.remove(_auth.username); // Исключаем себя
    return set.toList();
  }

  bool isRecent(String login) => _directory.recent.contains(login);

  void setAccessLevel(String value) {
    _accessLevel = value;
    notifyListeners();
  }

  /// Первичная загрузка справочника при открытии шторки.
  Future<void> loadDirectory() async {
    if (!_auth.isLoggedIn || _admin.users.isNotEmpty) return;
    _loadingUsers = true;
    notifyListeners();

    await _admin.loadDirectory();

    _loadingUsers = false;
    notifyListeners();
  }

  /// Принудительное обновление справочника по кнопке.
  Future<void> refreshDirectory() async {
    _loadingUsers = true;
    _error = null;
    notifyListeners();

    await _admin.loadDirectory();

    _loadingUsers = false;
    notifyListeners();
  }

  /// Выдача прав (viewer / editor).
  /// Возвращает null при успехе, или текст ошибки.
  Future<String?> share({
    required String serverId,
    required String targetLogin,
  }) async {
    final login = targetLogin.trim();
    if (login.isEmpty) return 'Укажите логин';

    _busy = true;
    _error = null;
    notifyListeners();

    final err = await _sharing.share(
      serverId: serverId,
      targetLogin: login,
      accessLevel: _accessLevel,
    );

    if (err == null) {
      await _directory.remember(login); // Запоминаем для будущих подсказок
    } else {
      _error = err;
      _busy = false;
      notifyListeners();
    }
    return err;
  }

  /// Передача прав владельца.
  /// Возвращает null при успехе, или текст ошибки.
  Future<String?> transferOwnership({
    required String serverId,
    required String targetLogin,
  }) async {
    final login = targetLogin.trim();
    if (login.isEmpty) return 'Укажите логин';

    _busy = true;
    _error = null;
    notifyListeners();

    final err = await _sharing.changeOwner(
      serverId: serverId,
      targetLogin: login,
    );

    if (err == null) {
      await _directory.remember(login);
    } else {
      _error = err;
      _busy = false;
      notifyListeners();
    }
    return err;
  }
}
