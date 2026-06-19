import 'package:dio/dio.dart';
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
    required String body,
  }) async {
    try {
      await _apiService.dio.post(endpoint, data: {'body': body});
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
