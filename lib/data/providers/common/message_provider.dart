import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';

class MessageProvider {
  final ApiService _apiService;

  MessageProvider(this._apiService);

  Future<Map<String, dynamic>> getThreads({
    required String endpoint,
    required int page,
    String? side,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'side': side};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiService.dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e('[MessageProvider] [getThreads] DioException: ${e.message}');
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch threads',
        );
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      logger.e('[MessageProvider] [getThreads] Unknown error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMessages({
    required String endpoint,
    required int page,
  }) async {
    try {
      final response = await _apiService.dio.get(
        endpoint,
        queryParameters: {'page': page},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e('[MessageProvider] [getMessages] DioException: ${e.message}');
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch messages',
        );
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      logger.e('[MessageProvider] [getMessages] Unknown error: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String endpoint,
    required String type,
    String? body,
    List<XFile>? images,
    Map<String, dynamic>? location,
  }) async {
    try {
      if (images != null && images.isNotEmpty) {
        final formData = FormData.fromMap({
          'type': type,
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
        });

        for (final image in images) {
          formData.files.add(
            MapEntry(
              'images[]',
              await MultipartFile.fromFile(image.path, filename: image.name),
            ),
          );
        }

        await _apiService.dio.post(endpoint, data: formData);
        return;
      }

      await _apiService.dio.post(
        endpoint,
        data: {
          'type': type,
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
          if (location != null && location.isNotEmpty) 'location': location,
        },
      );
    } on DioException catch (e) {
      logger.e('[MessageProvider] [sendMessage] DioException: ${e.message}');
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to send message',
        );
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      logger.e('[MessageProvider] [sendMessage] Unknown error: $e');
      rethrow;
    }
  }
}
