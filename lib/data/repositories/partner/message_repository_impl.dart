import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/data/models/chat_invitation_model.dart';
import 'package:sukientotapp/data/providers/common/message_provider.dart';
import 'package:sukientotapp/domain/api_url.dart';
import 'package:sukientotapp/domain/repositories/partner/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageProvider _provider;
  final String _endpoint;

  MessageRepositoryImpl(this._provider, {required String endpoint})
    : _endpoint = endpoint;

  @override
  Future<Map<String, dynamic>> getThreads({
    required int page,
    String? side,
    String? search,
  }) async {
    return _provider.getThreads(
      endpoint: _endpoint,
      page: page,
      side: side,
      search: search,
    );
  }

  @override
  Future<Map<String, dynamic>> getMessages({
    required String threadId,
    required int page,
  }) async {
    return _provider.getMessages(
      endpoint: AppUrl.chatMessages(threadId),
      page: page,
    );
  }

  @override
  Future<void> sendMessage({
    required String threadId,
    required String type,
    String? body,
    List<XFile>? images,
    Map<String, dynamic>? location,
  }) async {
    return _provider.sendMessage(
      endpoint: AppUrl.chatMessages(threadId),
      type: type,
      body: body,
      images: images,
      location: location,
    );
  }

  @override
  Future<Map<String, dynamic>> sendPriceIncreaseRequest({
    required String threadId,
    required int requestedPrice,
    required String reason,
    required String clientMessageId,
  }) => _provider.sendPriceIncreaseRequest(
    threadId: threadId,
    requestedPrice: requestedPrice,
    reason: reason,
    clientMessageId: clientMessageId,
  );

  @override
  Future<Map<String, dynamic>> getPriceIncreaseRequests({
    required int billId,
    required bool isPartner,
    required int page,
  }) => _provider.getPriceIncreaseRequests(
    billId: billId,
    isPartner: isPartner,
    page: page,
  );

  @override
  Future<Map<String, dynamic>> respondToPriceIncreaseRequest({
    required int orderId,
    required int requestId,
    required bool accept,
  }) => _provider.respondToPriceIncreaseRequest(
    orderId: orderId,
    requestId: requestId,
    accept: accept,
  );

  @override
  Future<List<ChatUserSearchResult>> searchUsersByPhone(String phone) =>
      _provider.searchUsersByPhone(phone: phone);

  @override
  Future<ChatInvitationResponse> inviteUser({
    required String threadId,
    required int userId,
  }) => _provider.inviteUser(threadId: threadId, userId: userId);

  @override
  Future<ChatInvitationResponse> acceptInvitation(String threadId) =>
      _provider.acceptInvitation(threadId: threadId);

  @override
  Future<String> leaveThread(String threadId) =>
      _provider.leaveThread(threadId: threadId);
}
