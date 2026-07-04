import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/event_order_model.dart';
import 'package:sukientotapp/data/models/client/history_order_model.dart';
import 'package:sukientotapp/data/models/client/order_detail_model.dart';
import 'package:sukientotapp/data/models/client/asset_order_model.dart';
import 'package:sukientotapp/data/providers/client/order_provider.dart';
import 'package:sukientotapp/domain/repositories/client/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderProvider _provider;

  OrderRepositoryImpl(this._provider);

  @override
  Future<({List<EventOrderModel> data, int lastPage})> getEventOrders({int page = 1}) async {
    try {
      final response = await _provider.getEventOrders(page: page);

      if (response != null && response['orders'] is Map && response['orders']['data'] is List) {
        final data = (response['orders']['data'] as List)
            .map((json) => EventOrderModel.fromJson(json))
            .toList();
        final meta = response['orders']['meta'];
        final lastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;
        return (data: data, lastPage: lastPage);
      } else if (response != null && response is List) {
        // Fallback for old API format
        final data = response.map((json) => EventOrderModel.fromJson(json)).toList();
        return (data: data, lastPage: 1);
      } else if (response != null && response['data'] is List) {
        final data = (response['data'] as List)
            .map((json) => EventOrderModel.fromJson(json))
            .toList();
        final meta = response['meta'];
        final lastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;
        return (data: data, lastPage: lastPage);
      }

      return (data: <EventOrderModel>[], lastPage: 1);
    } catch (e) {
      logger.e('Failed to parse getEventOrders response: $e');
      return (data: <EventOrderModel>[], lastPage: 1);
    }
  }

  @override
  Future<({List<HistoryOrderModel> data, int lastPage})> getHistoryOrders({int page = 1}) async {
    try {
      final response = await _provider.getHistoryOrders(page: page);

      if (response != null && response['orders'] is Map && response['orders']['data'] is List) {
        final data = (response['orders']['data'] as List)
            .map((json) => HistoryOrderModel.fromJson(json))
            .toList();
        final meta = response['orders']['meta'];
        final lastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;
        return (data: data, lastPage: lastPage);
      } else if (response != null && response is List) {
        // Fallback for old API format
        final data = response.map((json) => HistoryOrderModel.fromJson(json)).toList();
        return (data: data, lastPage: 1);
      } else if (response != null && response['data'] is List) {
        final data = (response['data'] as List)
            .map((json) => HistoryOrderModel.fromJson(json))
            .toList();
        final meta = response['meta'];
        final lastPage = meta != null ? (meta['last_page'] as int? ?? 1) : 1;
        return (data: data, lastPage: lastPage);
      }

      return (data: <HistoryOrderModel>[], lastPage: 1);
    } catch (e) {
      logger.e('Failed to parse getHistoryOrders response: $e');
      return (data: <HistoryOrderModel>[], lastPage: 1);
    }
  }

  @override
  Future<OrderDetailModel?> getOrderDetails(int orderId) async {
    try {
      final response = await _provider.getOrderDetails(orderId);
      if (response != null && response is Map<String, dynamic>) {
        return OrderDetailModel.fromJson(response);
      }
      return null;
    } catch (e) {
      logger.e('Failed to parse getOrderDetails response: $e');
      return null;
    }
  }

  @override
  Future<EventOrderModel?> getOrder(int orderId) async {
    try {
      final response = await _provider.getOrder(orderId);
      if (response != null && response is Map<String, dynamic>) {
        return EventOrderModel.fromJson(response);
      }
      return null;
    } catch (e) {
      logger.e('Failed to parse getOrder response: $e');
      return null;
    }
  }

  @override
  Future<HistoryOrderModel?> getHistoryOrder(int orderId) async {
    try {
      final response = await _provider.getHistoryOrder(orderId);
      if (response != null && response is Map<String, dynamic>) {
        return HistoryOrderModel.fromJson(response);
      }
      return null;
    } catch (e) {
      logger.e('Failed to parse getHistoryOrder response: $e');
      return null;
    }
  }

  @override
  Future<List<AssetOrderModel>> getAssetOrders() async {
    try {
      final response = await _provider.getAssetOrders();
      if (response != null && response is List) {
        return response
            .map((json) => AssetOrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      logger.e('Failed to parse getAssetOrders response: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> reportBill({
    required int reportedBillId,
    required String title,
    required String description,
  }) async {
    return _provider.reportBill(reportedBillId, title, description);
  }

  @override
  Future<Map<String, dynamic>> reportUser({
    required int reportedUserId,
    required String title,
    required String description,
  }) async {
    return _provider.reportUser(reportedUserId, title, description);
  }

  @override
  Future<Map<String, dynamic>> choosePartner({
    required int orderId,
    required int partnerId,
    String? voucherCode,
  }) async {
    try {
      final response = await _provider.choosePartner(orderId, partnerId, voucherCode: voucherCode);
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await _provider.cancelOrder(orderId);
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> submitReview({
    required int orderId,
    required int partnerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _provider.submitReview(
        orderId: orderId,
        partnerId: partnerId,
        rating: rating,
        comment: comment,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  @override
  Future<Map<String, dynamic>> validateVoucher({
    required int orderId,
    required String voucherInput,
  }) async {
    try {
      final response = await _provider.validateVoucher(
        orderId: orderId,
        voucherInput: voucherInput,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'status': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  @override
  Future<Map<String, dynamic>> removeVoucher({
    required int orderId,
  }) async {
    try {
      final response = await _provider.removeVoucher(orderId: orderId);
      return response as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> checkVoucherDiscount({
    required int orderId,
    required int partnerId,
    required String voucherInput,
  }) async {
    try {
      final response = await _provider.checkVoucherDiscount(
        orderId: orderId,
        partnerId: partnerId,
        voucherInput: voucherInput,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'status': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }
}
