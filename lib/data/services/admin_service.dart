import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/server_admin_card.dart';
import '../models/server_user.dart';
import '../remote/admin_api.dart';
import '../remote/public_api.dart';
import '../remote/user_api.dart';
import 'auth_service.dart';

class AdminService extends ChangeNotifier {
  AdminService({
    required AdminApi adminApi,
    required UserApi userApi,
    required PublicApi publicApi,
    required AuthService auth,
  }) : _adminApi = adminApi,
       _userApi = userApi,
       _publicApi = publicApi,
       _auth = auth {
    _auth.addListener(_onAuthChanged);
  }

  final AdminApi _adminApi;
  final UserApi _userApi;
  final PublicApi _publicApi;
  final AuthService _auth;

  List<ServerUser> _users = [];
  List<ServerUser> get users => List.unmodifiable(_users);

  List<ServerAdminCard> _allCards = [];
  List<ServerAdminCard> get allCards => List.unmodifiable(_allCards);

  bool _loadingUsers = false;
  bool get loadingUsers => _loadingUsers;

  bool _loadingCards = false;
  bool get loadingCards => _loadingCards;

  bool _checkingServer = false;
  bool get checkingServer => _checkingServer;

  String? _lastError;
  String? get lastError => _lastError;

  String? _serverStatus;
  String? get serverStatus => _serverStatus;

  bool _roleChecked = false;
  bool get roleChecked => _roleChecked;

  /// Проверяет, является ли текущий пользователь админом (пробует запросить список юзеров).
  Future<void> checkRole() async {
    if (!_auth.isLoggedIn) {
      _roleChecked = false;
      await _auth.setAdmin(false);
      return;
    }
    try {
      await _adminApi.getUsers();
      await _auth.setAdmin(true);
    } on DioException catch (e) {
      debugPrint('checkRole: status=${e.response?.statusCode}');
      await _auth.setAdmin(false);
    } catch (_) {
      await _auth.setAdmin(false);
    } finally {
      _roleChecked = true;
      notifyListeners();
    }
  }

  void _onAuthChanged() {
    if (!_auth.isLoggedIn) {
      _users = [];
      _allCards = [];
      _roleChecked = false;
      notifyListeners();
    }
  }

  // --- Пользователи ---

  /// Загружает ПОЛНЫЙ список пользователей (только для админа).
  Future<void> loadUsers() async {
    if (!_auth.isAdmin) return;
    _loadingUsers = true;
    _lastError = null;
    notifyListeners();
    try {
      _users = await _adminApi.getUsers();
    } on DioException catch (e) {
      _lastError = _humanError(e);
    } catch (e) {
      _lastError = 'Ошибка: $e';
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  /// Загружает краткий справочник (логин и имя) для автодополнения при шеринге.
  Future<void> loadDirectory() async {
    if (!_auth.isLoggedIn) return;
    _loadingUsers = true;
    notifyListeners();
    try {
      _users = await _userApi.getDirectory();
    } catch (_) {
      // Тихо игнорируем
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> registerUser({
    required String login,
    required String userName,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      await _adminApi.registerUser(
        login: login,
        userName: userName,
        password: password,
      );
      if (isAdmin) await _adminApi.setUserRole(login: login, isAdmin: true);
      await loadUsers();
      return true;
    } on DioException catch (e) {
      _lastError = _humanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> setRole(String login, bool isAdmin) async {
    try {
      await _adminApi.setUserRole(login: login, isAdmin: isAdmin);
      await loadUsers();
      return true;
    } on DioException catch (e) {
      _lastError = _humanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> resetPasswordToRandom(String login) async {
    try {
      return await _userApi.resetPasswordToRandom(login);
    } on DioException catch (e) {
      _lastError = _humanError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> changePassword({
    required String login,
    required String password,
  }) async {
    try {
      await _userApi.updatePassword(login: login, password: password);
      return true;
    } on DioException catch (e) {
      _lastError = _humanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String login) async {
    try {
      await _adminApi.deleteUser(login);
      await loadUsers();
      return true;
    } on DioException catch (e) {
      _lastError = _humanError(e);
      notifyListeners();
      return false;
    }
  }

  // --- Все карты (Админ) ---

  Future<void> loadAllCards() async {
    if (!_auth.isAdmin) return;
    _loadingCards = true;
    _lastError = null;
    notifyListeners();
    try {
      _allCards = await _adminApi.getAllCards();
    } on DioException catch (e) {
      _lastError = _humanError(e);
    } catch (e) {
      _lastError = 'Ошибка: $e';
    } finally {
      _loadingCards = false;
      notifyListeners();
    }
  }

  Future<void> checkServerStatus() async {
    _checkingServer = true;
    _lastError = null;
    notifyListeners();
    try {
      _serverStatus = await _publicApi.checkStatus() ?? 'OK';
    } on DioException catch (e) {
      _serverStatus = null;
      _lastError = _humanError(e);
    } catch (e) {
      _serverStatus = null;
      _lastError = '$e';
    } finally {
      _checkingServer = false;
      notifyListeners();
    }
  }

  /// Собирает данные для миграции (экспорт всех юзеров с хешами и карт).
  Future<Map<String, dynamic>?> prepareMigrationData() async {
    if (!_auth.isAdmin) return null;
    try {
      _loadingUsers = true;
      _loadingCards = true;
      notifyListeners();

      final usersRaw = await _adminApi.getUsersForMigration();
      final cards = await _adminApi.getAllCards();

      _loadingUsers = false;
      _loadingCards = false;
      notifyListeners();

      return {
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'users': usersRaw,
        'cards': cards
            .map(
              (c) => {
                'name': c.name,
                'barcode': c.barcode,
                'about': c.about,
                'owner_login': c.ownerLogin,
              },
            )
            .toList(),
      };
    } catch (e) {
      _lastError = e.toString();
      _loadingUsers = false;
      _loadingCards = false;
      notifyListeners();
      return null;
    }
  }

  String _humanError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 403) return 'Недостаточно прав';
    if (code == 404) return 'Пользователь не найден';
    if (code == 401) return 'Сессия истекла';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Сервер не отвечает';
    }
    return 'Ошибка: ${code ?? e.message}';
  }
}
