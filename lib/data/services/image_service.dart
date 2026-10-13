import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../remote/api_client.dart';

class ImageService {
  ImageService(this._apiClient);
  final ApiClient _apiClient;
  final _picker = ImagePicker();

  Future<File?> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    return x == null ? null : File(x.path);
  }

  Future<File?> takePhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );
    return x == null ? null : File(x.path);
  }

  Future<String?> upload({required String serverId, required File file}) async {
    try {
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
      if (data is String && data.isNotEmpty) return data;
      if (data is Map && data['image'] is String) {
        return data['image'] as String;
      }
      return '';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) return 'Недостаточно прав';
      if (code == 404) return 'Карта не найдена';
      if (e.type == DioExceptionType.connectionError) {
        return 'Сервер не отвечает';
      }
      return 'Ошибка загрузки: ${code ?? e.message}';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }
}
