import 'dart:io';

import 'package:dio/dio.dart';

import '../models/server_card.dart';
import 'api_client.dart';

/// API для работы с картами (CRUD, шеринг, картинки).
class CardApi {
  CardApi(this._apiClient);
  final ApiClient _apiClient;

  // --- Чтение ---

  Future<List<ServerCard>> getCards() async {
    final res = await _apiClient.client.get('/cards/');
    return _list(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ServerCard.fromJson)
        .where((c) => !c.isEmpty)
        .toList();
  }

  // --- Создание / Обновление ---

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

  // --- Удаление ---

  Future<void> deleteCard(String serverId) async {
    await _apiClient.client.delete('/cards/$serverId');
  }

  // --- Шеринг ---

  Future<void> shareCard({
    required String serverId,
    required String targetLogin,
    required String accessLevel,
  }) async {
    await _apiClient.client.post(
      '/cards/$serverId/share',
      data: {'target_login': targetLogin, 'access_level': accessLevel},
    );
  }

  Future<void> changeOwner({
    required String serverId,
    required String targetLogin,
  }) async {
    await _apiClient.client.put(
      '/cards/$serverId/owner',
      data: {'target_login': targetLogin},
    );
  }

  // --- Картинки ---

  Future<String?> uploadImage({
    required String serverId,
    required File file,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });
    final res = await _apiClient.client.put(
      '/cards/$serverId/image',
      data: form,
    );
    final data = res.data;

    // Сервер может вернуть строку или объект {"image": "..."}
    if (data is String && data.isNotEmpty) return data;
    if (data is Map && data['image'] is String) return data['image'] as String;
    return '';
  }

  // --- Парсеры ---

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
