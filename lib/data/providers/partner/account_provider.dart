import 'package:dio/dio.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

class AccountProvider {
  final ApiService _apiService;

  AccountProvider(this._apiService);

  Future<List<Map<String, dynamic>>> getWalletTransactions() async {
    try {
      final response = await _apiService.dio.get(
        AppUrl.partnerWalletTransactions,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception(
        'Failed to load wallet transactions: ${response.statusCode}',
      );
    } on DioException catch (e) {
      logger.e(
        '[AccountProvider] [getWalletTransactions] DioException: ${e.message}',
      );
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to load wallet transactions',
        );
      }
      throw Exception(
        'Cannot connect to server. Please check your connection.',
      );
    }
  }

  Future<Map<String, dynamic>> confirmAddFunds({
    required String orderCode,
    required String status,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.partnerWalletConfirmAddFunds,
        data: {'orderCode': orderCode, 'status': status},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Confirmation failed: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[AccountProvider] [confirmAddFunds] DioException: ${e.message}',
      );
      throw Exception(
        e.response?.data['message'] ?? 'Cannot connect to server.',
      );
    }
  }

  Future<String> regenerateAddFundsLink(int amount) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.partnerWalletRegenerateAddFundsLink,
        data: {'amount': amount},
      );
      if (response.statusCode == 200) {
        final checkoutUrl = response.data['checkoutUrl'] as String?;
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('Invalid payment URL received.');
        }
        return checkoutUrl;
      }
      throw Exception('Failed to create payment link: ${response.statusCode}');
    } on DioException catch (e) {
      logger.e(
        '[AccountProvider] [regenerateAddFundsLink] DioException: ${e.message}',
      );
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to initiate payment.',
        );
      }
      throw Exception(
        'Cannot connect to server. Please check your connection.',
      );
    }
  }

  Future<void> logout() async {
    try {
      final deviceId =
          StorageService.readData(key: LocalStorageKeys.pushDeviceId)
              as String?;
      final response = await _apiService.dio.get(
        AppUrl.logout,
        queryParameters: {
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Logout failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[AccountProvider] [logout] DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('unauthorized');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Cannot connect to server.',
      );
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final response = await _apiService.dio.delete(
        AppUrl.deleteAccount,
        data: {'password': password},
      );
      if (response.statusCode != 200) {
        throw Exception('Delete account failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[AccountProvider] [deleteAccount] DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('unauthorized');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Cannot connect to server.',
      );
    }
  }
}
