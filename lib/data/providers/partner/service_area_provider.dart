import 'package:dio/dio.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

class PartnerServiceAreaProvider {
  final ApiService _apiService;

  PartnerServiceAreaProvider(this._apiService);

  Future<Map<String, dynamic>> getServiceAreas({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiService.dio.get(
        AppUrl.partnerServiceAreas,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to load service areas: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[PartnerServiceAreaProvider] [getServiceAreas] DioException: ${e.message}',
      );
      throw Exception(_messageFromDio(e, 'Failed to load service areas'));
    } catch (e) {
      logger.e('[PartnerServiceAreaProvider] [getServiceAreas] $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addServiceAreas(
    List<int> locationIds, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.partnerServiceAreas,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
        data: {'location_ids': locationIds},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to add service areas: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[PartnerServiceAreaProvider] [addServiceAreas] DioException: ${e.message}',
      );
      throw Exception(_messageFromDio(e, 'Failed to add service areas'));
    } catch (e) {
      logger.e('[PartnerServiceAreaProvider] [addServiceAreas] $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateServiceAreas(
    List<int> locationIds, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.partnerServiceAreasUpdate,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
        data: {'location_ids': locationIds},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to update service areas: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[PartnerServiceAreaProvider] [updateServiceAreas] DioException: ${e.message}',
      );
      throw Exception(_messageFromDio(e, 'Failed to update service areas'));
    } catch (e) {
      logger.e('[PartnerServiceAreaProvider] [updateServiceAreas] $e');
      rethrow;
    }
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (e.response != null) return fallback;
    return 'Cannot connect to server. Please check your connection.';
  }
}
