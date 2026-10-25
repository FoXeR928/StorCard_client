import 'package:dio/dio.dart';

import '../services/auth_service.dart';

class UnauthorizedException implements Exception {
  @override
  String toString() => 'Unauthorized';
}

/// Обертка над Dio.
/// Автоматически подставляет URL и токен, а также перехватывает 401 (протухший токен).
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

    // Пересоздаем клиент, если URL изменился
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
            // Подставляем актуальный токен
            final t = _auth.token;
            if (t != null) o.headers['Authorization'] = 'Bearer $t';
            h.next(o);
          },
          onError: (e, h) async {
            // Если токен протух (401) и это не запрос на логин/рефреш
            final isAuthPath = e.requestOptions.path.contains('/auth/');

            if (e.response?.statusCode == 401 && !isAuthPath) {
              final refreshed = await _auth.refreshAccessToken();
              if (refreshed) {
                // Пробуем повторить запрос с новым токеном
                try {
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer ${_auth.token}';
                  final retryDio = Dio(BaseOptions(baseUrl: opts.baseUrl));
                  final resp = await retryDio.fetch(opts);
                  return h.resolve(resp);
                } catch (_) {
                  // Если повтор упал — идем в обработку ошибки
                }
              }
              // Если обновить не удалось — разлогиниваем
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
