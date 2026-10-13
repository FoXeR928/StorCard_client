import '../models/server_admin_card.dart';
import '../models/server_user.dart';
import 'api_client.dart';

class AdminApi {
  AdminApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<ServerUser>> getUsers() async {
    final res = await _apiClient.client.get('/users/');
    return _list(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ServerUser.fromJson)
        .toList();
  }

  Future<String?> checkStatus() async {
    final res = await _apiClient.client.get('/status');
    final data = res.data;
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      return (data['status'] ?? data['message'] ?? data.toString()).toString();
    }
    return data.toString();
  }

  Future<void> registerUser({
    required String login,
    required String userName,
    required String password,
  }) async {
    await _apiClient.client.post(
      '/users/registration',
      data: {'login': login, 'user_name': userName, 'password': password},
    );
  }

  Future<void> setUserRole({
    required String login,
    required bool isAdmin,
  }) async {
    await _apiClient.client.patch(
      '/users/role',
      data: {'login': login, 'is_admin': isAdmin},
    );
  }

  Future<void> updatePassword({
    required String login,
    required String password,
  }) async {
    await _apiClient.client.patch(
      '/users/password',
      data: {'login': login, 'password': password},
    );
  }

  Future<void> deleteUser(String login) async {
    await _apiClient.client.delete('/users/$login');
  }

  Future<List<ServerAdminCard>> getAllCards() async {
    final res = await _apiClient.client.get('/cards/all');
    return _list(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ServerAdminCard.fromJson)
        .toList();
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in const ['users', 'cards', 'items', 'data', 'results']) {
        final v = data[k];
        if (v is List) return v;
      }
    }
    return const [];
  }
}
