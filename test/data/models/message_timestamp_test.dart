import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sukientotapp/data/models/message_model.dart';

void main() {
  final DateTime sentAt = DateTime.utc(2026, 10, 21, 10);
  Locale? originalLocale;
  setUpAll(() {
    originalLocale = Get.locale;
    Get.addTranslations(<String, Map<String, String>>{
      'vi_VN': <String, String>{
        'just_now': 'vừa xong',
        'minute_ago': '@count phút trước',
        'minutes_ago': '@count phút trước',
        'hour_ago': '@count giờ trước',
        'hours_ago': '@count giờ trước',
      },
    });
    Get.locale = const Locale('vi', 'VN');
  });
  tearDownAll(() => Get.locale = originalLocale);

  MessageModel optimistic() => MessageModel(
    text: 'Hello',
    isSender: true,
    sended: false,
    time: 'vừa xong',
    date: '',
    createdAt: sentAt,
  );

  test('local sent message ages without resetting its send time', () {
    final MessageModel sent = optimistic().copyWith(sended: true);
    expect(sent.createdAt, sentAt);
    expect(sent.sended, isTrue);
    expect(sent.timeAt(sentAt.add(const Duration(seconds: 59))), 'vừa xong');
    expect(sent.timeAt(sentAt.add(const Duration(minutes: 1))), '1 phút trước');
    expect(sent.timeAt(sentAt.add(const Duration(minutes: 5))), '5 phút trước');
    expect(sent.timeAt(sentAt.add(const Duration(hours: 1))), '1 giờ trước');
  });

  test('received realtime message retains server time and ages', () {
    final MessageModel incoming = MessageModel.fromApiJson(<String, dynamic>{
      'sender_id': 8,
      'message': <String, dynamic>{
        'id': 99,
        'thread_id': 1,
        'user_id': 8,
        'body': 'Hello',
        'created_at': '2026-10-21T17:00:00+07:00',
      },
      'user': <String, dynamic>{'id': 8, 'name': 'Client'},
    }, currentUserId: 7);
    expect(incoming.isSender, isFalse);
    expect(incoming.createdAt, sentAt);
    expect(
      incoming.timeAt(sentAt.add(const Duration(minutes: 12))),
      '12 phút trước',
    );
  });

  test('POST file/video timestamps survive local serialization', () {
    for (final String type in <String>['file', 'video']) {
      final MessageModel message = MessageModel.fromApiJson(<String, dynamic>{
        'success': true,
        'message': <String, dynamic>{
          'id': 99,
          'user_id': 7,
          'type': type,
          'created_at': sentAt.toIso8601String(),
        },
      }, currentUserId: 7);
      final MessageModel restored = MessageModel.fromJson(message.toJson());
      expect(restored.createdAt, sentAt);
      expect(
        restored.timeAt(sentAt.add(const Duration(minutes: 10))),
        '10 phút trước',
      );
    }
  });

  test('legacy data without an absolute time keeps its display fallback', () {
    final MessageModel legacy = MessageModel.fromJson(<String, dynamic>{
      'text': 'Old message',
      'time': '2 ngày trước',
    });
    expect(legacy.createdAt, isNull);
    expect(legacy.timeAt(sentAt), '2 ngày trước');
  });
}
