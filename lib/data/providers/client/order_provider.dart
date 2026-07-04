import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/api_url.dart';
import 'package:dio/dio.dart';

class OrderProvider {
  final Dio _dio;

  OrderProvider({required Dio dio}) : _dio = dio;

  Future<dynamic> getEventOrders({int page = 1}) async {
    try {
      final response = await _dio.get('${AppUrl.clientOrders}?page=$page');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> getHistoryOrders({int page = 1}) async {
    try {
      final response = await _dio.get('${AppUrl.clientHistoryOrders}?page=$page');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> getOrderDetails(int orderId) async {
    try {
      final response = await _dio.get(AppUrl.clientOrderDetail(orderId));
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> getOrder(int orderId) async {
    try {
      final response = await _dio.get(AppUrl.clientOrder(orderId));
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> getHistoryOrder(int orderId) async {
    try {
      final response = await _dio.get(AppUrl.clientHistoryOrder(orderId));
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> getAssetOrders() async {
    try {
      final response = await _dio.get(AppUrl.clientAssetOrders);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'fetch_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<Map<String, dynamic>> reportBill(int billId, String title, String description) async {
    try {
      final response = await _dio.post(
        AppUrl.reportBill,
        data: {
          'reported_bill_id': billId,
          'title': title,
          'description': description,
        },
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 422) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'fetch_failed'.tr,
          'errors': e.response?.data['errors'] ?? {},
        };
      }
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'network_error'.tr,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> reportUser(
    int reportedUserId,
    String title,
    String description,
  ) async {
    try {
      final response = await _dio.post(
        AppUrl.reportUser,
        data: {'reported_user_id': reportedUserId, 'title': title, 'description': description},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 422) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'fetch_failed'.tr,
          'errors': e.response?.data['errors'] ?? {},
        };
      }
      return {'success': false, 'message': e.response?.data?['message'] ?? 'network_error'.tr};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<dynamic> choosePartner(int orderId, int partnerId, {String? voucherCode}) async {
    try {
      final response = await _dio.post(
        AppUrl.choosePartner,
        data: {
          'order_id': orderId,
          'partner_id': partnerId,
          if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];
          if (errors != null) {
            final firstErrorMsg = errors.values.first.first;
            throw Exception(firstErrorMsg);
          }
        }
        throw Exception(e.response?.data['message'] ?? 'choose_partner_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> cancelOrder(int orderId) async {
    try {
      final response = await _dio.post(
        AppUrl.cancelOrder,
        data: {
          'order_id': orderId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'cancel_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> submitReview({
    required int orderId,
    required int partnerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        AppUrl.submitReview,
        data: {
          'order_id': orderId,
          'partner_id': partnerId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'submit_review_failed'.tr);
      }
      throw Exception('network_error'.tr);
    }
  }

  Future<dynamic> validateVoucher({
    required int orderId,
    required String voucherInput,
  }) async {
    try {
      final response = await _dio.post(
        AppUrl.validateVoucher,
        data: {
          'order_id': orderId,
          'voucher_input': voucherInput,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'status': false,
          'message': e.response?.data['message'] ?? 'voucher_validation_failed'.tr,
        };
      }
      return {
        'status': false,
        'message': 'network_error'.tr,
      };
    }
  }

  Future<dynamic> removeVoucher({
    required int orderId,
  }) async {
    try {
      final response = await _dio.post(
        AppUrl.removeVoucher,
        data: {
          'bill_id': orderId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'remove_voucher_failed'.tr,
        };
      }
      return {
        'success': false,
        'message': 'network_error'.tr,
      };
    }
  }

  Future<dynamic> checkVoucherDiscount({
    required int orderId,
    required int partnerId,
    required String voucherInput,
  }) async {
    try {
      final response = await _dio.post(
        AppUrl.checkVoucherDiscount,
        data: {
          'order_id': orderId,
          'partner_id': partnerId,
          'voucher_input': voucherInput,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'status': false,
          'message': e.response?.data['message'] ?? 'fetch_failed'.tr,
        };
      }
      return {
        'status': false,
        'message': 'network_error'.tr,
      };
    }
  }
}
