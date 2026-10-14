import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_result.dart';

class AuthService extends ChangeNotifier {
  static const _kServerUrl = 'server_url';
  static const _kToken = 'auth_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUsername = 'auth_username';
  static const _kOffline = 'offline_mode';
  static const _kIsAdmin = 'is_admin';
  static const _kLastServerUrl = 'last_server_url';

  /// Обновляем access-токен заранее, до его истечения.
  static const _refreshLead = Duration(minutes: 5);

  String? _serverUrl;
  String? _token;
  String? _refreshToken;
  String? _username;
  bool _offlineMode = false;
  bool _isAdmin = false;
  String? _lastServerUrl;

  /// Событие для UI: сюда пишем сообщение при провале обновления токена.
  final sessionExpired = ValueNotifier<String?>(null);

  Timer? _refreshTimer;
  Future<bool>? _refreshInFlight;

  String? get serverUrl => _serverUrl;
  String? get token => _token;
  String? get username => _username;
  String? get lastServerUrl => _lastServerUrl;
  bool get isLoggedIn => _token != null && _serverUrl != null;
  bool get offlineMode => _offlineMode;
  bool get isAdmin => _isAdmin;
  bool get isReady => isLoggedIn || _offlineMode;

  // ------------------------------------------------------------
  // Восстановление состояния
  // ------------------------------------------------------------

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _serverUrl = p.getString(_kServerUrl);
    _token = p.getString(_kToken);
    _refreshToken = p.getString(_kRefresh);
    _username = p.getString(_kUsername);
    _offlineMode = p.getBool(_kOffline) ?? false;
    _isAdmin = p.getBool(_kIsAdmin) ?? false;
    _lastServerUrl = p.getString(_kLastServerUrl);
    notifyListeners();
    if (isLoggedIn) _scheduleRefresh();
  }

  // ------------------------------------------------------------
  // Логин
  // ------------------------------------------------------------

  Future<AuthResult> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final normalized = serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return AuthResult.failure(
        'Адрес должен начинаться с http:// или https://',
      );
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      final path = rememberMe ? '/auth/login?remember_me=true' : '/auth/login';

      final res = await dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'grant_type': 'password',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = res.data['access_token'] as String?;
      final refresh = res.data['refresh_token'] as String?;
      if (token == null) return AuthResult.failure('Сервер не вернул токен');

      final p = await SharedPreferences.getInstance();
      await p.setString(_kServerUrl, normalized);
      await p.setString(_kToken, token);
      if (refresh != null) await p.setString(_kRefresh, refresh);
      await p.setString(_kUsername, username);
      await p.setBool(_kOffline, false);
      await p.setString(_kLastServerUrl, normalized);
      await p.setBool(_kIsAdmin, false);

      _serverUrl = normalized;
      _token = token;
      _refreshToken = refresh;
      _username = username;
      _offlineMode = false;
      _isAdmin = false;
      _lastServerUrl = normalized;

      _scheduleRefresh();
      notifyListeners();
      return AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_humanError(e));
    } catch (e) {
      return AuthResult.failure('Неизвестная ошибка: $e');
    }
  }

  // ------------------------------------------------------------
  // Refresh
  // ------------------------------------------------------------

  Future<bool> refreshAccessToken() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = _doRefresh();
    _refreshInFlight = future;
    future.whenComplete(() => _refreshInFlight = null);
    return future;
  }

  Future<bool> _doRefresh() async {
    final refresh = _refreshToken;
    final url = _serverUrl;
    if (refresh == null || url == null) return false;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final res = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final newAccess = res.data['access_token'] as String?;
      if (newAccess == null) return false;

      _token = newAccess;
      final p = await SharedPreferences.getInstance();
      await p.setString(_kToken, newAccess);

      _scheduleRefresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // Фоновое обновление токена
  // ------------------------------------------------------------

  /// Парсит exp из JWT (payload — без проверки подписи).
  DateTime? _parseTokenExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ставит таймер: обновить access-токен за `_refreshLead` до истечения.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final token = _token;
    if (token == null || _serverUrl == null || _refreshToken == null) return;

    final exp = _parseTokenExp(token);
    if (exp == null) return;

    final remaining = exp.difference(DateTime.now());
    final delay = remaining - _refreshLead;

    if (delay.isNegative) {
      // Уже скоро истечёт — обновляем сразу.
      _runBackgroundRefresh();
      return;
    }

    _refreshTimer = Timer(delay, _runBackgroundRefresh);
  }

  Future<void> _runBackgroundRefresh() async {
    final ok = await refreshAccessToken();
    // При неудаче ничего не делаем: следующий 401 от ApiClient решит судьбу сессии.
    if (!ok) return;
  }

  // ------------------------------------------------------------
  // Прочее
  // ------------------------------------------------------------

  Future<void> setAdmin(bool value) async {
    if (_isAdmin == value) return;
    _isAdmin = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIsAdmin, value);
    notifyListeners();
  }

  Future<void> handleUnauthorized({String? reason}) async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final p = await SharedPreferences.getInstance();
    await p.remove(_kServerUrl);
    await p.remove(_kToken);
    await p.remove(_kRefresh);
    await p.remove(_kUsername);
    await p.setBool(_kOffline, true);
    await p.setBool(_kIsAdmin, false);

    _serverUrl = null;
    _token = null;
    _refreshToken = null;
    _username = null;
    _offlineMode = true;
    _isAdmin = false;

    sessionExpired.value =
        reason ?? 'Сессия истекла. Войдите в аккаунт заново.';
    notifyListeners();
  }

  Future<void> continueOffline() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOffline, true);
    _offlineMode = true;
    notifyListeners();
  }

  Future<void> rememberServerUrl(String url) async {
    final n = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (n.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastServerUrl, n);
    _lastServerUrl = n;
    notifyListeners();
  }

  Future<void> logout() async {
    final url = _serverUrl;
    final token = _token;
    if (url != null && token != null) {
      try {
        await Dio(BaseOptions(baseUrl: url)).post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {
        // Игнорируем — logout локально всё равно выполнится.
      }
    }

    _refreshTimer?.cancel();
    _refreshTimer = null;

    final p = await SharedPreferences.getInstance();
    await p.remove(_kServerUrl);
    await p.remove(_kToken);
    await p.remove(_kRefresh);
    await p.remove(_kUsername);
    await p.setBool(_kOffline, true);
    await p.setBool(_kIsAdmin, false);

    _serverUrl = null;
    _token = null;
    _refreshToken = null;
    _username = null;
    _offlineMode = true;
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> requireLogin() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOffline, false);
    _offlineMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    sessionExpired.dispose();
    super.dispose();
  }

  String _humanError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Сервер не отвечает. Проверь адрес и сеть.';
      case DioExceptionType.connectionError:
        return 'Не удалось подключиться. Проверь адрес и порт.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 400 || code == 403) {
          return 'Неверный логин или пароль';
        }
        return 'Ошибка сервера: $code';
      default:
        return e.message ?? 'Ошибка сети';
    }
  }
}
