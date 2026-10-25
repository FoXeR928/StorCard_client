import '../models/server_user.dart';
import 'api_client.dart';

class UserApi {
  UserApi(this._apiClient);
  final ApiClient _apiClient;

  /// Справочник пользователей для автодополнения при шеринге.
  Future<List<ServerUser>> getDirectory() async {
    final res = await _apiClient.client.get('/users/directory');
    return _list(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ServerUser.fromJson)
        .toList();
  }

  Future<String?> resetPasswordToRandom(String login) async {
    final res = await _apiClient.client.post(
      '/users/reset-password',
      data: {'login': login},
    );
    if (res.data is Map && res.data['password'] is String) {
      return res.data['password'] as String;
    }
    return null;
  }

  /// Смена пароля. Пользователь может менять свой, админ — любой.
  Future<void> updatePassword({
    required String login,
    required String password,
  }) async {
    await _apiClient.client.patch(
      '/users/password',
      data: {'login': login, 'password': password},
    );
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in const ['users', 'items', 'data', 'results']) {
        final v = data[k];
        if (v is List) return v;
      }
    }
    return const [];
  }
}
