class MessageBillModel {
  final int id;
  final String eventName;
  final String datetime;
  final String address;

  const MessageBillModel({
    required this.id,
    required this.eventName,
    required this.datetime,
    required this.address,
  });

  factory MessageBillModel.fromJson(Map<String, dynamic> json) {
    return MessageBillModel(
      id: json['id'] as int,
      eventName: json['event_name'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_name': eventName,
      'datetime': datetime,
      'address': address,
    };
  }
}

class MessageListModel {
  final String id;
  final String subject;
  final List<String> names;
  final String code;
  final String? newestMessage;
  final String? newestMessageSender;
  final String time;
  final bool isRead;
  final int unreadMessages;
  final MessageBillModel bill;

  MessageListModel({
    required this.id,
    this.subject = '',
    required this.names,
    required this.code,
    required this.newestMessage,
    required this.newestMessageSender,
    required this.time,
    required this.isRead,
    required this.unreadMessages,
    required this.bill,
  });

  factory MessageListModel.fromJson(Map<String, dynamic> json) {
    final participants = json['participants'] as List<dynamic>? ?? [];
    final latestMessage = json['latest_message'] as Map<String, dynamic>?;

    final participantNames = participants
        .map((p) => (p as Map<String, dynamic>)['name'] as String? ?? '')
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
                    : null);

    return MessageListModel(
      id: json['id'].toString(),
      subject: json['subject'] as String? ?? '',
      names: participantNames,
      code: json['code'] as String? ?? '',
      newestMessage: latestPreviewText,
      newestMessageSender: latestMessage?['sender_name'] as String?,
      time: latestMessage?['created_at'] as String? ?? '',
      isRead: !isUnread,
      unreadMessages: isUnread ? 1 : 0,
      bill: MessageBillModel.fromJson(json['bill'] as Map<String, dynamic>),
    );
  }

  MessageListModel copyWith({
    String? id,
    String? subject,
    List<String>? names,
    String? code,
    String? newestMessage,
    String? newestMessageSender,
    String? time,
    bool? isRead,
    int? unreadMessages,
    MessageBillModel? bill,
  }) {
    return MessageListModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      names: names ?? this.names,
      code: code ?? this.code,
      newestMessage: newestMessage ?? this.newestMessage,
      newestMessageSender: newestMessageSender ?? this.newestMessageSender,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      bill: bill ?? this.bill,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'names': names,
      'newestMessage': newestMessage,
      'newestMessageSender': newestMessageSender,
      'time': time,
      'isRead': isRead,
      'unreadMessages': unreadMessages,
      'bill': bill.toJson(),
    };
  }
}
