import 'package:image_picker/image_picker.dart';
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
}
