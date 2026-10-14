import 'package:flutter/foundation.dart';

import '../data/services/admin_service.dart';
import '../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this._auth, required AdminService admin})
    : _admin = admin;

  final AuthService _auth;
  final AdminService _admin;

  bool _loading = false;
  String? _error;
  bool _rememberMe = false; 

  bool get loading => _loading;
  String? get error => _error;
  String? get lastServerUrl => _auth.lastServerUrl;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    if (_rememberMe == value) return;
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await _auth.rememberServerUrl(serverUrl);

    final result = await _auth.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
      rememberMe: _rememberMe,
    );

    if (!result.isSuccess) {
      _loading = false;
      _error = result.error;
      notifyListeners();
      return false;
    }

    await _admin.checkRole();
    _loading = false;
    notifyListeners();
    return true;
  }

  Future<void> continueOffline() => _auth.continueOffline();
}
