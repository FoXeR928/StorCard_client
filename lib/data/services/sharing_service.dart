import 'package:dio/dio.dart';

import '../remote/card_api.dart';

class SharingService {
  SharingService(this._api);
  final CardApi _api;

  Future<String?> share({
    required String serverId,
    required String targetLogin,
    required String accessLevel,
  }) async {
    try {
      await _api.shareCard(
        serverId: serverId,
        targetLogin: targetLogin,
        accessLevel: accessLevel,
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
      await _api.changeOwner(serverId: serverId, targetLogin: targetLogin);
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
