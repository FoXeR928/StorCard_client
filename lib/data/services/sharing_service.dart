import 'package:dio/dio.dart';

import '../remote/api_client.dart';

class SharingService {
  SharingService(this._apiClient);
  final ApiClient _apiClient;

  /// null — успех, иначе текст ошибки.
  Future<String?> share({
    required String serverId,
    required String targetLogin,
    required String accessLevel,
  }) async {
    try {
      await _apiClient.client.post(
        '/cards/$serverId/share',
        data: {'target_login': targetLogin, 'access_level': accessLevel},
      );
      return null;
    } on DioException catch (e) {
      return _humanError(e);
    }
  }

  Future<String?> changeOwner({
    required String serverId,
    required String targetLogin,
  }) async {
    try {
      await _apiClient.client.put(
        '/cards/$serverId/owner',
        data: {'target_login': targetLogin},
      );
      return null;
    } on DioException catch (e) {
      return _humanError(e);
    }
  }

  String _humanError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String? detail;
    if (data is Map && data['detail'] != null) {
      detail = data['detail'].toString();
    }
    if (code == 403) return detail ?? 'Недостаточно прав';
    if (code == 404) return detail ?? 'Пользователь не найден';
    if (code == 409) return detail ?? 'Уже есть доступ';
    if (code == 401) return 'Сессия истекла';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Сервер не отвечает';
    }
    return detail ?? 'Ошибка: ${code ?? e.message}';
  }
}
