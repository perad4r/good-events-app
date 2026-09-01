class MessageBillModel {
  final int id;
  final String eventName;
  final String datetime;
  final String address;
  final String status;
  final int? total;
  final int? partnerId;

  const MessageBillModel({
    required this.id,
    required this.eventName,
    required this.datetime,
    required this.address,
    this.status = '',
    this.total,
    this.partnerId,
  });

  factory MessageBillModel.fromJson(Map<String, dynamic> json) {
    return MessageBillModel(
      id: json['id'] as int,
      eventName: json['event_name'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status']?.toString() ?? '',
      total: _asInt(json['total'] ?? json['final_total']),
      partnerId: _asInt(json['partner_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_name': eventName,
      'datetime': datetime,
      'address': address,
      'status': status,
      'total': total,
      'partner_id': partnerId,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}

class MessageThreadParticipant {
  const MessageThreadParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.role,
  });

  final int id;
  final String name;
  final String? avatar;
  final String? role;

  factory MessageThreadParticipant.fromJson(Map<String, dynamic> json) =>
      MessageThreadParticipant(
        id: (json['id'] ?? json['user_id']) is int
            ? (json['id'] ?? json['user_id']) as int
            : int.tryParse((json['id'] ?? json['user_id'])?.toString() ?? '') ??
                  0,
        name: json['name']?.toString() ?? '',
        avatar: json['avatar']?.toString(),
        role: json['role']?.toString().toLowerCase(),
      );
}

class MessageListModel {
  final String id;
  final String subject;
  final List<String> names;
  final List<MessageThreadParticipant> participants;
  final String code;
  final String? newestMessage;
  final String? newestMessageSender;
  final String? newestMessageSenderAvatar;
  final String time;
  final bool isRead;
  final int unreadMessages;
  final MessageBillModel bill;
  final bool canLeave;

  MessageListModel({
    required this.id,
    this.subject = '',
    required this.names,
    this.participants = const [],
    required this.code,
    required this.newestMessage,
    required this.newestMessageSender,
    this.newestMessageSenderAvatar,
    required this.time,
    required this.isRead,
    required this.unreadMessages,
    required this.bill,
    this.canLeave = false,
  });

  factory MessageListModel.fromJson(Map<String, dynamic> json) {
    final participants = json['participants'] as List<dynamic>? ?? [];
    final latestMessage = json['latest_message'] as Map<String, dynamic>?;

    final typedParticipants = participants
        .whereType<Map<String, dynamic>>()
        .map(MessageThreadParticipant.fromJson)
        .toList(growable: false);
    final participantNames = typedParticipants
        .map((p) => p.name)
        .where((name) => name.isNotEmpty)
        .toList();

    final isUnread = json['is_unread'] as bool? ?? false;
    final latestType = latestMessage?['type'] as String? ?? 'text';
    final latestBody = latestMessage?['body'] as String? ?? '';
    final latestPreviewText =
        (latestMessage?['preview_text'] as String?) ??
        (latestBody.isNotEmpty
            ? latestBody
            : latestType == 'image'
            ? '[Ảnh]'
                : latestType == 'location'
                    ? 'Vị trí hiện tại'
                    : latestType == 'call'
                        ? '[Cuộc gọi]'
                        : latestType == 'price_increase_request'
                            ? '[Yêu cầu tăng giá]'
                    : null);

    return MessageListModel(
      id: json['id'].toString(),
      subject: json['subject'] as String? ?? '',
      names: participantNames,
      participants: typedParticipants,
      code: json['code'] as String? ?? '',
      newestMessage: latestPreviewText,
      newestMessageSender: latestMessage?['sender_name'] as String?,
      newestMessageSenderAvatar: latestMessage?['sender_avatar']?.toString(),
      time: latestMessage?['created_at'] as String? ?? '',
      isRead: !isUnread,
      unreadMessages: isUnread ? 1 : 0,
      bill: MessageBillModel.fromJson(json['bill'] as Map<String, dynamic>),
      canLeave: _parseCanLeave(json),
    );
  }

  static bool _parseCanLeave(Map<String, dynamic> json) {
    if (json['can_leave'] is bool) return json['can_leave'] as bool;
    if (json['membership_source']?.toString() == 'invitation') return true;
    final membership = json['membership'];
    if (membership is Map<String, dynamic>) {
      if (membership['can_leave'] is bool) {
        return membership['can_leave'] as bool;
      }
      return membership['source']?.toString() == 'invitation';
    }
    return false;
  }

  MessageListModel copyWith({
    String? id,
    String? subject,
    List<String>? names,
    List<MessageThreadParticipant>? participants,
    String? code,
    String? newestMessage,
    String? newestMessageSender,
    String? newestMessageSenderAvatar,
    String? time,
    bool? isRead,
    int? unreadMessages,
    MessageBillModel? bill,
    bool? canLeave,
  }) {
    return MessageListModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      names: names ?? this.names,
      participants: participants ?? this.participants,
      code: code ?? this.code,
      newestMessage: newestMessage ?? this.newestMessage,
      newestMessageSender: newestMessageSender ?? this.newestMessageSender,
      newestMessageSenderAvatar:
          newestMessageSenderAvatar ?? this.newestMessageSenderAvatar,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      bill: bill ?? this.bill,
      canLeave: canLeave ?? this.canLeave,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'names': names,
      'participants': participants
          .map((p) => {'id': p.id, 'name': p.name, 'avatar': p.avatar})
          .toList(),
      'newestMessage': newestMessage,
      'newestMessageSender': newestMessageSender,
      'newestMessageSenderAvatar': newestMessageSenderAvatar,
      'time': time,
      'isRead': isRead,
      'unreadMessages': unreadMessages,
      'bill': bill.toJson(),
      'can_leave': canLeave,
    };
  }
}
