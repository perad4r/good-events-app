import 'package:sukientotapp/data/models/message_list_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';

/// Upload responses/realtime can omit avatars that history already provides.
String? resolveMessageSenderAvatar({
  required MessageModel message,
  required Iterable<MessageModel> history,
  required Iterable<MessageThreadParticipant> participants,
  int? currentUserId,
  String? currentUserAvatar,
  String? alternateCurrentUserAvatar,
}) {
  String? nonEmpty(String? value) {
    final String? normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  final String? direct = nonEmpty(message.senderAvatar);
  if (direct != null) return direct;

  final bool isCurrentUser = message.userId != null && currentUserId != null
      ? message.userId == currentUserId
      : message.isSender;
  if (isCurrentUser) {
    final String? stored =
        nonEmpty(currentUserAvatar) ?? nonEmpty(alternateCurrentUserAvatar);
    if (stored != null) return stored;
  }

  for (final MessageModel previous in history) {
    final bool sameSender = message.userId != null
        ? previous.userId == message.userId
        : message.sender.isNotEmpty && previous.sender == message.sender;
    final String? avatar = nonEmpty(previous.senderAvatar);
    if (sameSender && avatar != null) return avatar;
  }
  for (final MessageThreadParticipant participant in participants) {
    final bool sameSender = message.userId != null
        ? participant.id == message.userId
        : message.sender.isNotEmpty && participant.name == message.sender;
    final String? avatar = nonEmpty(participant.avatar);
    if (sameSender && avatar != null) return avatar;
  }
  return null;
}
