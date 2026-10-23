import 'package:flutter_test/flutter_test.dart';
import 'package:sukientotapp/data/models/message_list_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:sukientotapp/features/common/message/message_avatar_resolver.dart';

MessageModel _message({
  int? userId = 7,
  String? avatar,
  bool outgoing = false,
  String name = 'Sender',
}) => MessageModel(
  userId: userId,
  sender: name,
  senderAvatar: avatar,
  type: 'file',
  text: '',
  isSender: outgoing,
  sended: true,
  time: '',
  date: '',
);

void main() {
  test('keeps the avatar supplied by POST/history/realtime', () {
    expect(
      resolveMessageSenderAvatar(
        message: _message(avatar: 'https://media.example/direct.png'),
        history: <MessageModel>[
          _message(avatar: 'https://media.example/old.png'),
        ],
        participants: const <MessageThreadParticipant>[],
      ),
      'https://media.example/direct.png',
    );
  });

  test(
    'outgoing attachment with null payload avatar uses the signed-in user',
    () {
      expect(
        resolveMessageSenderAvatar(
          message: _message(outgoing: true),
          history: const <MessageModel>[],
          participants: const <MessageThreadParticipant>[],
          currentUserId: 7,
          currentUserAvatar: '  https://media.example/me.png  ',
        ),
        'https://media.example/me.png',
      );
    },
  );

  test('upload uses the alternate stored avatar when avatar_url is empty', () {
    expect(
      resolveMessageSenderAvatar(
        message: _message(outgoing: true),
        history: const <MessageModel>[],
        participants: const <MessageThreadParticipant>[],
        currentUserId: 7,
        currentUserAvatar: ' ',
        alternateCurrentUserAvatar: 'https://media.example/me.png',
      ),
      'https://media.example/me.png',
    );
  });

  test('incoming attachment reuses the same sender avatar from history', () {
    expect(
      resolveMessageSenderAvatar(
        message: _message(),
        history: <MessageModel>[
          _message(userId: 8, avatar: 'https://media.example/other.png'),
          _message(avatar: 'https://media.example/sender.png'),
        ],
        participants: const <MessageThreadParticipant>[],
        currentUserId: 8,
        currentUserAvatar: 'https://media.example/me.png',
      ),
      'https://media.example/sender.png',
    );
  });

  test('same display name never overrides a known sender ID', () {
    expect(
      resolveMessageSenderAvatar(
        message: _message(),
        history: <MessageModel>[
          _message(userId: 8, avatar: 'https://media.example/wrong.png'),
        ],
        participants: const <MessageThreadParticipant>[
          MessageThreadParticipant(
            id: 7,
            name: 'Sender',
            avatar: 'https://media.example/right.png',
          ),
        ],
      ),
      'https://media.example/right.png',
    );
  });

  test('missing incoming avatar stays unresolved for history enrichment', () {
    expect(
      resolveMessageSenderAvatar(
        message: _message(),
        history: const <MessageModel>[],
        participants: const <MessageThreadParticipant>[],
        currentUserId: 8,
        currentUserAvatar: 'https://media.example/me.png',
      ),
      isNull,
    );
  });
}
