import '../models/server_card.dart';
import 'api_client.dart';

class SyncApi {
  SyncApi(this._apiClient);
  final ApiClient _apiClient;

  Future<List<ServerCard>> getCards() async {
    final res = await _apiClient.client.get('/cards/');
    return _list(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ServerCard.fromJson)
        .where((c) => !c.isEmpty)
        .toList();
  }

  Future<ServerCard?> createCard({
    required String name,
    required String barcode,
    String? about,
  }) async {
    final res = await _apiClient.client.post(
      '/cards/',
      data: {
        'name': name,
        'barcode': barcode,
        if (about != null && about.isNotEmpty) 'about': about,
      },
    );
    return _parse(res.data);
  }

  Future<ServerCard?> updateCard({
    required String serverId,
    String? name,
    String? barcode,
    String? about,
  }) async {
    final res = await _apiClient.client.patch(
      '/cards/$serverId',
      data: {'name': ?name, 'barcode': ?barcode, 'about': about},
    );
    return _parse(res.data);
  }

  Future<void> deleteCard(String serverId) async {
    await _apiClient.client.delete('/cards/$serverId');
  }

  ServerCard? _parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final c = ServerCard.fromJson(data);
      if (!c.isEmpty) return c;
    }
    return null;
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in const ['cards', 'items', 'data', 'results']) {
        final v = data[k];
        if (v is List) return v;
      }
    }
    throw FormatException(
      'Ожидался список карт, получено: ${data.runtimeType}',
    );
  }
}
