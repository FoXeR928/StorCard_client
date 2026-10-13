import 'package:dio/dio.dart';

import '../services/auth_service.dart';

class UnauthorizedException implements Exception {
  @override
  String toString() => 'Unauthorized';
}

/// Dio-обёртка:
/// 1. Подставляет baseUrl + Bearer access-токен.
/// 2. При 401 — пытается обновить токен через /auth/refresh, повторяет запрос.
/// 3. Если refresh не удался — помечает сессию сломанной и бросает UnauthorizedException.
class ApiClient {
  ApiClient(this._auth);

  final AuthService _auth;
  Dio? _dio;
  String? _cachedBaseUrl;

  Dio get client {
    final url = _auth.serverUrl;
    if (url == null) {
      throw StateError('Нет адреса сервера. Пользователь не залогинен.');
    }
    if (_dio == null || _cachedBaseUrl != url) {
      _cachedBaseUrl = url;
      _dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            final t = _auth.token;
            if (t != null) o.headers['Authorization'] = 'Bearer $t';
            h.next(o);
          },
          onError: (e, h) async {
            // Не пытаемся рефрешить сам /auth/refresh и /auth/login
            final isAuthPath = e.requestOptions.path.contains('/auth/');

            if (e.response?.statusCode == 401 && !isAuthPath) {
              final refreshed = await _auth.refreshAccessToken();
              if (refreshed) {
                // Повторяем исходный запрос с новым токеном
                try {
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer ${_auth.token}';
                  final retryDio = Dio(BaseOptions(baseUrl: opts.baseUrl));
                  final resp = await retryDio.fetch(opts);
                  return h.resolve(resp);
                } catch (_) {
                  // Повтор тоже упал — обрабатываем как 401
                }
              }
              await _auth.handleUnauthorized();
              h.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  error: UnauthorizedException(),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            h.next(e);
          },
        ),
      );
    }
    return _dio!;
  }

  void reset() {
    _dio = null;
    _cachedBaseUrl = null;
  }
}
