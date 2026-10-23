import 'package:flutter_test/flutter_test.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';

void main() {
  group('attachment validation', () {
    for (final ChatAttachmentType type in ChatAttachmentType.values) {
      final int limit = type == ChatAttachmentType.file ? 20971520 : 52428800;
      for (final int delta in <int>[-1, 0, 1]) {
        test('${type.name} byte boundary $delta', () {
          final ChatAttachmentSelection selection = ChatAttachmentSelection(
            type: type,
            path: '/tmp/source',
            name: type == ChatAttachmentType.file ? 'QUOTE.PDF' : 'CLIP.MP4',
            size: limit + delta,
          );
          expect(selection.validate(), delta <= 0 ? isNull : isNotNull);
        });
      }
    }
    test('rejects empty, mixed and unsupported attachments', () {
      for (final String name in <String>[
        'malware.exe',
        'quote.pdf.exe',
        'noextension',
        'clip.mp4',
      ]) {
        expect(
          ChatAttachmentSelection(
            type: ChatAttachmentType.file,
            path: '/tmp/source',
            name: name,
            size: 12,
          ).validate(),
          isNotNull,
        );
      }
      expect(
        const ChatAttachmentSelection(
          type: ChatAttachmentType.video,
          path: '/tmp/source',
          name: 'clip.mp4',
          size: 0,
        ).validate(),
        'chat_attachment_empty',
      );
    });
    test('accepts every documented file extension', () {
      for (final String extension in ChatAttachmentSelection.fileExtensions) {
        expect(
          ChatAttachmentSelection(
            type: ChatAttachmentType.file,
            path: '/tmp/source',
            name: 'source.$extension',
            size: 1,
          ).validate(),
          isNull,
        );
      }
    });
  });

  group('attachment envelopes', () {
    final Map<String, dynamic> message = <String, dynamic>{
      'id': 1208,
      'thread_id': 27,
      'user_id': 42,
      'type': 'file',
      'body': null,
      'attachments': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 305,
          'name': 'quote.pdf',
          'file_name': 'uuid.pdf',
          'mime_type': null,
          'size': 123456,
          'url': 'https://media.example/uuid.pdf',
        },
      ],
    };
    final Map<String, dynamic> user = <String, dynamic>{
      'id': 42,
      'name': 'Client',
      'avatar': 'https://media.example/avatar.png',
    };
    test('POST resolves message.user and fallback filename preview', () {
      final MessageModel parsed = MessageModel.fromApiJson(<String, dynamic>{
        'success': true,
        'message': <String, dynamic>{...message, 'user': user},
      }, currentUserId: 42);
      expect(parsed.sender, 'Client');
      expect(parsed.senderAvatar, user['avatar']);
      expect(parsed.isSender, isTrue);
      expect(parsed.previewText, '[Tệp] quote.pdf');
      expect(parsed.attachments.single.mimeType, isEmpty);
      expect(parsed.attachments.single.url, 'https://media.example/uuid.pdf');
    });
    test('history and realtime resolve the outer sender', () {
      final MessageModel parsed = MessageModel.fromApiJson(<String, dynamic>{
        'sender_id': 42,
        'message': message,
        'user': user,
      }, currentUserId: 7);
      expect(parsed.sender, 'Client');
      expect(parsed.isSender, isFalse);
      expect(parsed.id, 1208);
    });
    test('video is independent of call and handles empty attachments', () {
      final MessageModel parsed = MessageModel.fromApiJson(<String, dynamic>{
        ...message,
        'type': 'video',
        'attachments': null,
      }, currentUserId: 7);
      expect(parsed.previewText, '[Video]');
      expect(parsed.attachments, isEmpty);
      expect(parsed.call, isNull);
    });
    test('server preview overrides the caption fallback', () {
      final MessageModel parsed = MessageModel.fromApiJson(<String, dynamic>{
        ...message,
        'body': 'caption',
        'preview_text': 'Server preview',
      }, currentUserId: 7);
      expect(parsed.previewText, 'Server preview');
    });
  });
}
