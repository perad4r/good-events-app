import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/domain/api_url.dart';

class ShowProvider {
  final ApiService _apiService;

  ShowProvider(this._apiService);

  Future<Map<String, dynamic>> getBills({
    required String status,
    String? search,
    String dateFilter = 'all',
    String sort = 'date_asc',
    int page = 1,
    int perPage = 5,
  }) async {
    final queryParams = <String, dynamic>{
      'date_filter': dateFilter,
      'sort': sort,
      'page': page,
      'per_page': perPage,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final endpoint =
        status == 'history'
            ? AppUrl.partnerBillsHistory
            : AppUrl.partnerBills(status);

    final response = await _apiService.dio.get(
      endpoint,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load bills for status: $status');
    }
  }

  Future<bool> markInJob(int billId, XFile image) async {
    final formData = FormData.fromMap({
      'arrival_photo': await MultipartFile.fromFile(
        image.path,
        filename: image.name,
      ),
    });
    final response = await _apiService.dio.post(
      AppUrl.partnerBillMarkInJob(billId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.statusCode == 200;
  }

  Future<bool> completeBill(int billId) async {
    final response = await _apiService.dio.post(AppUrl.partnerBillComplete(billId));
    return response.statusCode == 200;
  }

  Future<bool> cancelAcceptBill(int billId) async {
    final response = await _apiService.dio.post(AppUrl.billCancel(billId));
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getBillReview(int billId) async {
    final response = await _apiService.dio.get(AppUrl.partnerBillReview(billId));

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load review for bill: $billId');
    }
  }
}
