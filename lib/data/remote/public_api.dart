import 'api_client.dart';

class PublicApi {
  PublicApi(this._apiClient);
  final ApiClient _apiClient;

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
}
