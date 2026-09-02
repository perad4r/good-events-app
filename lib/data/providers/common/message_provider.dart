import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/data/models/chat_invitation_model.dart';
import 'package:sukientotapp/domain/api_url.dart';

class ChatApiException implements Exception {
  const ChatApiException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class MessageProvider {
  final ApiService _apiService;

  MessageProvider(this._apiService);
  CancelToken? _userSearchCancelToken;

  Future<List<ChatUserSearchResult>> searchUsersByPhone({
    required String phone,
  }) async {
    _userSearchCancelToken?.cancel('Superseded by a newer search');
    final cancelToken = CancelToken();
    _userSearchCancelToken = cancelToken;
    try {
      final response = await _apiService.dio.get<Map<String, dynamic>>(
        AppUrl.chatUserSearch,
        queryParameters: <String, dynamic>{'phone': phone},
        cancelToken: cancelToken,
      );
      final users = response.data?['users'] as List<dynamic>? ?? const [];
      return users
          .whereType<Map<String, dynamic>>()
          .map(ChatUserSearchResult.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      throw _chatException(error, fallback: 'Không thể tìm người dùng.');
    }
  }

  Future<ChatInvitationResponse> inviteUser({
    required String threadId,
    required int userId,
  }) async {
    try {
      final response = await _apiService.dio.post<Map<String, dynamic>>(
        AppUrl.chatInvitations(threadId),
        data: <String, int>{'user_id': userId},
      );
      return ChatInvitationResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw _chatException(error, fallback: 'Không thể gửi lời mời.');
    }
  }

  Future<ChatInvitationResponse> acceptInvitation({
    required String threadId,
  }) async {
    try {
      final response = await _apiService.dio.post<Map<String, dynamic>>(
        AppUrl.acceptChatInvitation(threadId),
      );
      return ChatInvitationResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw _chatException(error, fallback: 'Không thể chấp nhận lời mời.');
    }
  }

  Future<String> leaveThread({required String threadId}) async {
    try {
      final response = await _apiService.dio.delete<Map<String, dynamic>>(
        AppUrl.leaveChatThread(threadId),
      );
      return response.data?['message'] as String? ?? 'Bạn đã rời đoạn chat.';
    } on DioException catch (error) {
      throw _chatException(error, fallback: 'Không thể rời đoạn chat.');
    }
  }

  ChatApiException _chatException(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    String? validationMessage;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            validationMessage = value.first.toString();
            break;
          }
        }
      }
      validationMessage ??= data['message']?.toString();
    }
    return ChatApiException(
      message: validationMessage ?? fallback,
      statusCode: error.response?.statusCode,
    );
  }

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

  Future<Map<String, dynamic>> sendPriceIncreaseRequest({
    required String threadId,
    required int requestedPrice,
    required String reason,
    required String clientMessageId,
  }) async {
    try {
      final response = await _apiService.dio.post<Map<String, dynamic>>(
        AppUrl.chatMessages(threadId),
        data: <String, dynamic>{
          'client_message_id': clientMessageId,
          'type': 'price_increase_request',
          'requested_price': requestedPrice,
          'reason': reason.trim(),
        },
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _chatException(error, fallback: 'Không thể gửi yêu cầu tăng giá.');
    }
  }

  Future<Map<String, dynamic>> getPriceIncreaseRequests({
    required int billId,
    required bool isPartner,
    required int page,
  }) async {
    try {
      final response = await _apiService.dio.get<Map<String, dynamic>>(
        isPartner
            ? AppUrl.partnerPriceIncreaseRequests(billId)
            : AppUrl.clientPriceIncreaseRequests(billId),
        queryParameters: <String, dynamic>{'page': page, 'per_page': 20},
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _chatException(error, fallback: 'Không thể tải lịch sử tăng giá.');
    }
  }

  Future<Map<String, dynamic>> respondToPriceIncreaseRequest({
    required int orderId,
    required int requestId,
    required bool accept,
  }) async {
    try {
      final response = await _apiService.dio.post<Map<String, dynamic>>(
        accept
            ? AppUrl.acceptPriceIncreaseRequest(orderId, requestId)
            : AppUrl.rejectPriceIncreaseRequest(orderId, requestId),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _chatException(
        error,
        fallback: accept
            ? 'Không thể đồng ý yêu cầu tăng giá.'
            : 'Không thể từ chối yêu cầu tăng giá.',
      );
    }
  }
}
