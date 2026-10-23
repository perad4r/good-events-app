import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/services/chat_media_service.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_list_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:sukientotapp/data/providers/common/message_provider.dart';
import 'package:sukientotapp/domain/repositories/partner/message_repository.dart';
import 'package:sukientotapp/features/common/message/controller.dart';

class _Calls extends Fake implements CallCoordinator {}

class _Media extends ChatMediaService {
  @override
  Future<void> removeLocal(String path) async {}
}

class _Repository extends Fake implements MessageRepository {
  final List<String> uuids = <String>[];
  final List<Completer<MessageModel>> uploads = <Completer<MessageModel>>[];
  Future<Map<String, dynamic>> Function(String thread, int page)? history;

  @override
  Future<MessageModel> sendAttachment({
    required String threadId,
    required ChatAttachmentSelection attachment,
    required String caption,
    required String clientMessageId,
    required int? currentUserId,
    required void Function(int, int) onProgress,
    required CancelToken cancelToken,
  }) {
    uuids.add(clientMessageId);
    final Completer<MessageModel> response = Completer<MessageModel>();
    uploads.add(response);
    unawaited(() async {
      final DioException error = await cancelToken.whenCancel;
      if (!response.isCompleted) response.completeError(error);
    }());
    onProgress(50, 100);
    return response.future;
  }

  @override
  Future<Map<String, dynamic>> getMessages({
    required String threadId,
    required int page,
  }) => history!(threadId, page);
}

MessageListModel _thread(String id) => MessageListModel(
  id: id,
  names: const <String>[],
  code: '',
  newestMessage: null,
  newestMessageSender: null,
  time: '',
  isRead: true,
  unreadMessages: 0,
  bill: const MessageBillModel(id: 1, eventName: '', datetime: '', address: ''),
);

Map<String, dynamic> _raw(int id, {String body = ''}) => <String, dynamic>{
  'id': id,
  'thread_id': 1,
  'user_id': 7,
  'type': 'file',
  'body': body,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MessageController controller;
  late _Repository repository;

  setUp(() {
    Get.testMode = true;
    Get.put<ChatMediaService>(_Media());
    repository = _Repository();
    controller = MessageController(repository, _Calls());
    controller.selectedThread.value = _thread('1');
  });
  tearDown(() async {
    await controller.disposeUploads();
    controller.onClose();
    Get.reset();
  });

  ChatUploadTask task() => ChatUploadTask(
    clientMessageId: 'same-logical-message',
    threadId: '1',
    caption: 'quote',
    attachment: const ChatAttachmentSelection(
      type: ChatAttachmentType.file,
      path: '/tmp/quote.pdf',
      name: 'quote.pdf',
      size: 10,
    ),
  );

  test(
    'lost response retries the same UUID and replaces a server duplicate',
    () async {
      final ChatUploadTask pending = task();
      controller.attachmentUploads.add(pending);
      final Future<void> first = controller.retryAttachment(pending);
      expect(pending.progress, .5);
      repository.uploads.first.completeError(
        const ChatApiException(message: 'network lost'),
      );
      await first;
      expect(pending.status, ChatUploadStatus.failed);
      final MessageModel confirmed = MessageModel.fromApiJson(
        _raw(99),
        currentUserId: 7,
      );
      controller.messagesDetail.add(confirmed);
      final Future<void> retry = controller.retryAttachment(pending);
      repository.uploads.last.complete(confirmed);
      await retry;
      expect(repository.uuids, <String>[
        pending.clientMessageId,
        pending.clientMessageId,
      ]);
      expect(controller.attachmentUploads, isEmpty);
      expect(
        controller.messagesDetail.map((MessageModel message) => message.id),
        <int>[99],
      );
    },
  );

  test(
    'user-channel duplicates do not duplicate messages or unread counts',
    () {
      controller.filteredMessages.add(_thread('1'));
      final PusherEvent event = PusherEvent(
        channelName: 'private-user-messages.7',
        eventName: 'SendMessage',
        data: <String, dynamic>{
          'sender_id': 8,
          'message': <String, dynamic>{..._raw(88), 'user_id': 8},
          'user': <String, Object>{
            'id': 8,
            'name': 'Client',
            'avatar': 'https://media.example/client.png',
          },
        },
      );
      controller.onUserChannelEvent(event);
      controller.onUserChannelEvent(event);
      expect(controller.messagesDetail, hasLength(1));
      expect(controller.filteredMessages.single.unreadMessages, 0);
      controller.closeThread();
      final PusherEvent next = PusherEvent(
        channelName: 'private-user-messages.7',
        eventName: 'SendMessage',
        data: <String, dynamic>{
          'sender_id': 8,
          'message': <String, dynamic>{..._raw(89), 'user_id': 8},
        },
      );
      controller.onUserChannelEvent(next);
      controller.onUserChannelEvent(next);
      expect(controller.filteredMessages.single.unreadMessages, 1);
    },
  );

  test(
    'logout cancels an active upload before clearing session media',
    () async {
      final ChatUploadTask pending = task();
      controller.attachmentUploads.add(pending);
      final Future<void> upload = controller.retryAttachment(pending);
      await controller.disposeUploads();
      await upload;
      expect(controller.attachmentUploads, isEmpty);
      expect(controller.messagesDetail, isEmpty);
    },
  );

  test('incoming video without an avatar is enriched from history', () async {
    final Completer<Map<String, dynamic>> response =
        Completer<Map<String, dynamic>>();
    int historyCalls = 0;
    repository.history = (String _, int page) {
      historyCalls++;
      return response.future;
    };
    controller.onUserChannelEvent(
      PusherEvent(
        channelName: 'private-user-messages.7',
        eventName: 'SendMessage',
        data: <String, dynamic>{
          'sender_id': 8,
          'message': <String, dynamic>{
            ..._raw(90),
            'user_id': 8,
            'type': 'video',
          },
          'user': <String, Object?>{'id': 8, 'name': 'Client', 'avatar': null},
        },
      ),
    );
    expect(historyCalls, 1);
    response.complete(<String, dynamic>{
      'messages': <Object>[
        <String, dynamic>{
          'sender_id': 8,
          'message': <String, dynamic>{
            ..._raw(90),
            'user_id': 8,
            'type': 'video',
          },
          'user': <String, Object>{
            'id': 8,
            'name': 'Client',
            'avatar': 'https://media.example/client.png',
          },
        },
      ],
      'hasMore': false,
    });
    await Future<void>.delayed(Duration.zero);
    expect(controller.messagesDetail, hasLength(1));
    expect(
      controller.resolveSenderAvatar(controller.messagesDetail.single),
      'https://media.example/client.png',
    );
  });

  test('upload completion does not insert into a different thread', () async {
    final ChatUploadTask pending = task();
    controller.attachmentUploads.add(pending);
    final Future<void> upload = controller.retryAttachment(pending);
    controller.selectedThread.value = _thread('2');
    repository.uploads.single.complete(
      MessageModel.fromApiJson(_raw(99), currentUserId: 7),
    );
    await upload;
    expect(controller.messagesDetail, isEmpty);
    expect(controller.attachmentUploads, isEmpty);
  });

  test('failed uploads remain scoped to their original thread', () {
    final ChatUploadTask pending = task()..status = ChatUploadStatus.failed;
    controller.attachmentUploads.add(pending);
    expect(controller.visibleUploads, <ChatUploadTask>[pending]);
    controller.closeThread();
    controller.selectedThread.value = _thread('2');
    expect(controller.visibleUploads, isEmpty);
    controller.selectedThread.value = _thread('1');
    expect(controller.visibleUploads, <ChatUploadTask>[pending]);
  });

  test(
    'overlapping pages deduplicate and refresh updates existing metadata',
    () async {
      repository.history = (String _, int page) async => <String, dynamic>{
        'messages': page == 1
            ? <Object>[_raw(12), _raw(13)]
            : <Object>[_raw(11), _raw(12)],
        'hasMore': page == 1,
      };
      await controller.loadMessages();
      await controller.loadOlderMessages();
      expect(
        controller.messagesDetail.map((MessageModel message) => message.id),
        <int>[13, 12, 11],
      );
      repository.history = (String _, int page) async => <String, dynamic>{
        'messages': <Object>[_raw(13, body: 'updated')],
        'hasMore': false,
      };
      await controller.loadMessages();
      expect(controller.messagesDetail.first.text, 'updated');
      expect(
        controller.messagesDetail.where(
          (MessageModel message) => message.id == 13,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'late history response is ignored after closing an empty thread',
    () async {
      final Completer<Map<String, dynamic>> response =
          Completer<Map<String, dynamic>>();
      repository.history = (String _, int page) => response.future;
      final Future<void> loading = controller.loadMessages();
      controller.closeThread();
      controller.selectedThread.value = _thread('2');
      response.complete(<String, dynamic>{
        'messages': <Object>[_raw(99)],
        'hasMore': false,
      });
      await loading;
      expect(controller.messagesDetail, isEmpty);
      expect(controller.selectedThreadId, '2');
    },
  );
}
