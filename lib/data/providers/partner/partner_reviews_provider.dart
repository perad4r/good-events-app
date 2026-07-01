import 'package:dio/dio.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

class PartnerReviewsProvider {
  final ApiService _apiService;

  PartnerReviewsProvider(this._apiService);

  Future<Map<String, dynamic>> getReviews({
    required int page,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiService.dio.get(
        AppUrl.partnerReviews,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to load reviews: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[PartnerReviewsProvider] [getReviews] DioException: ${e.message}',
      );
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load reviews',
        );
      }
      throw Exception(
        'Cannot connect to server. Please check your connection.',
      );
    } catch (e) {
      logger.e('[PartnerReviewsProvider] [getReviews] Unknown error: $e');
      rethrow;
    }
  }
}
