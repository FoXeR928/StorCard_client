import 'package:flutter/foundation.dart';

import '../data/services/admin_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/recipient_directory.dart';
import '../data/services/sharing_service.dart';

class ShareViewModel extends ChangeNotifier {
  ShareViewModel({
    required this._auth,
    required AdminService admin,
    required this._sharing,
    required this._directory,
  }) : _admin = admin;

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
  bool get isAdmin => _auth.isAdmin;

  List<String> candidates() {
    final set = <String>{..._directory.recent};
    if (_auth.isAdmin) set.addAll(_admin.users.map((u) => u.login));
    set.remove(_auth.username);
    return set.toList();
  }

  bool isRecent(String login) => _directory.recent.contains(login);

  void setAccessLevel(String value) {
    _accessLevel = value;
    notifyListeners();
  }

  Future<void> loadUsersIfAdmin() async {
    if (!_auth.isAdmin || _admin.users.isNotEmpty) return;
    _loadingUsers = true;
    notifyListeners();
    await _admin.loadUsers();
    _loadingUsers = false;
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    if (!_auth.isAdmin) {
      _error = 'Список доступен только администраторам';
      notifyListeners();
      return;
    }
    _loadingUsers = true;
    _error = null;
    notifyListeners();
    await _admin.loadUsers();
    _loadingUsers = false;
    notifyListeners();
  }

  /// null = успех. Иначе текст ошибки.
  Future<String?> share({
    required String serverId,
    required String targetLogin,
  }) async {
    if (targetLogin.trim().isEmpty) return 'Укажите логин';
    _busy = true;
    _error = null;
    notifyListeners();

    final err = await _sharing.share(
      serverId: serverId,
      targetLogin: targetLogin.trim(),
      accessLevel: _accessLevel,
    );

    if (err == null) {
      await _directory.remember(targetLogin.trim());
    } else {
      _error = err;
      _busy = false;
      notifyListeners();
    }
    return err;
  }

  Future<String?> transferOwnership({
    required String serverId,
    required String targetLogin,
  }) async {
    if (targetLogin.trim().isEmpty) return 'Укажите логин';
    _busy = true;
    _error = null;
    notifyListeners();

    final err = await _sharing.changeOwner(
      serverId: serverId,
      targetLogin: targetLogin.trim(),
    );

    if (err == null) {
      await _directory.remember(targetLogin.trim());
    } else {
      _error = err;
      _busy = false;
      notifyListeners();
    }
    return err;
  }
}
