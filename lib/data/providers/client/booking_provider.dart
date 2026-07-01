import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/domain/api_url.dart';
import 'package:sukientotapp/core/utils/logger.dart';

class BookingProvider {
  final Dio _dio;

  BookingProvider({required Dio dio}) : _dio = dio;

  Future<List<Map<String, dynamic>>> getEventTypes() async {
    try {
      final response = await _dio.get(AppUrl.quickBookingEventList);
      if (response.data is List) {
        return (response.data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed');
      }
      throw Exception('network_error');
    }
  }

  Future<Map<String, dynamic>> saveBookingInfo(
    Map<String, dynamic> payload, {
    List<XFile> bookingPhotos = const [],
  }) async {
    try {
      final Object requestData;
      final Options? options;

      if (bookingPhotos.isNotEmpty) {
        final formData = FormData.fromMap(payload);
        for (final photo in bookingPhotos) {
          formData.files.add(
            MapEntry(
              'booking_photos[]',
              await MultipartFile.fromFile(photo.path, filename: photo.name),
            ),
          );
        }

        requestData = formData;
        options = Options(contentType: 'multipart/form-data');
      } else {
        requestData = payload;
        options = null;
      }

      if (requestData is FormData) {
        logger.d('Request fields: ${requestData.fields}');
        logger.d(
          'Request files: ${requestData.files.map((entry) => '${entry.key}: ${entry.value.filename}').toList()}',
        );
      } else {
        logger.d('Request Data: $requestData');
      }

      final response = await _dio.post(
        AppUrl.quickBookingSave,
        data: requestData,
        options: options,
      );
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 422) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'booking_failed',
          'errors': e.response?.data['errors'] ?? {},
        };
      }
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'network_error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
