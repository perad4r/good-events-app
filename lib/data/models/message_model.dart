import 'package:sukientotapp/core/utils/import/global.dart';

class MessageAttachmentModel {
  final int? id;
  final String name;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;
  final String localPath;

  const MessageAttachmentModel({
    this.id,
    this.name = '',
    this.fileName = '',
    this.mimeType = '',
    this.size = 0,
    this.url = '',
    this.localPath = '',
  });

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      size: _asInt(json['size']) ?? 0,
      url: json['url'] as String? ?? '',
      localPath: json['local_path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_name': fileName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      'local_path': localPath,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class MessageLocationModel {
  final double latitude;
  final double longitude;
  final String? label;
  final String? address;

  const MessageLocationModel({
    required this.latitude,
    required this.longitude,
    this.label,
    this.address,
  });

  factory MessageLocationModel.fromJson(Map<String, dynamic> json) {
    return MessageLocationModel(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      label: json['label'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'address': address,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CallMessageSummary {
  const CallMessageSummary({
    required this.id,
    required this.durationSeconds,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;

  String get formattedDuration => formatDuration(durationSeconds);

  static String formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours giờ');
    if (minutes > 0) parts.add('$minutes phút');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds giây');
    return parts.join(' ');
  }

  factory CallMessageSummary.fromJson(Map<String, dynamic> json) =>
      CallMessageSummary(
        id: json['id']?.toString() ?? '',
        durationSeconds: _asInt(json['duration_seconds']) ?? 0,
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
        endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'duration_seconds': durationSeconds,
    'started_at': startedAt?.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
  };

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class PriceIncreaseRequestModel {
  const PriceIncreaseRequestModel({
    required this.id,
    required this.orderId,
    required this.partnerId,
    required this.originalTotal,
    required this.requestedTotal,
    required this.reason,
    required this.status,
    this.messageId,
    this.respondedBy,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int orderId;
  final int partnerId;
  final int? messageId;
  final int originalTotal;
  final int requestedTotal;
  final String reason;
  final String status;
  final int? respondedBy;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';

  PriceIncreaseRequestModel copyWith({String? status}) {
    return PriceIncreaseRequestModel(
      id: id,
      orderId: orderId,
      partnerId: partnerId,
      messageId: messageId,
      originalTotal: originalTotal,
      requestedTotal: requestedTotal,
      reason: reason,
      status: status ?? this.status,
      respondedBy: respondedBy,
      respondedAt: respondedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PriceIncreaseRequestModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return PriceIncreaseRequestModel(
      id: asInt(json['id']),
      orderId: asInt(json['order_id'] ?? json['partner_bill_id']),
      partnerId: asInt(json['partner_id']),
      messageId: json['message_id'] == null ? null : asInt(json['message_id']),
      originalTotal: asInt(json['original_total']),
      requestedTotal: asInt(json['requested_total']),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      respondedBy: json['responded_by'] == null ? null : asInt(json['responded_by']),
      respondedAt: DateTime.tryParse(json['responded_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'partner_id': partnerId,
    'message_id': messageId,
    'original_total': originalTotal,
    'requested_total': requestedTotal,
    'reason': reason,
    'status': status,
    'responded_by': respondedBy,
    'responded_at': respondedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class MessageModel {
  final int? id;
  final int? threadId;
  final int? userId;
  final String sender;
  final String? senderAvatar;
  final String text;
  final String type;
  final String previewText;
  final List<MessageAttachmentModel> attachments;
  final MessageLocationModel? location;
  final CallMessageSummary? call;
  final PriceIncreaseRequestModel? priceIncreaseRequest;
  final bool isSender;
  final bool sended;
  final String time;
  final String date;

  MessageModel({
    this.id,
    this.sender = '',
    this.senderAvatar,
    this.threadId,
    this.userId,
    required this.text,
    this.type = 'text',
    String? previewText,
    this.attachments = const [],
    this.location,
    this.call,
    this.priceIncreaseRequest,
    required this.isSender,
    required this.sended,
    required this.time,
    required this.date,
  }) : previewText = previewText ?? text;

  MessageModel copyWith({PriceIncreaseRequestModel? priceIncreaseRequest}) {
    return MessageModel(
      id: id,
      threadId: threadId,
      userId: userId,
      sender: sender,
      senderAvatar: senderAvatar,
      text: text,
      type: type,
      previewText: previewText,
      attachments: attachments,
      location: location,
      call: call,
      priceIncreaseRequest:
          priceIncreaseRequest ?? this.priceIncreaseRequest,
      isSender: isSender,
      sended: sended,
      time: time,
      date: date,
    );
  }

  /// Converts an ISO 8601 timestamp string to a human-readable relative time.
  static String diffForHumans(String isoString) {
    if (isoString.isEmpty) return '';
    final DateTime? dateTime = DateTime.tryParse(isoString);
    if (dateTime == null) return isoString;
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just_now'.tr;
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return (m == 1 ? 'minute_ago' : 'minutes_ago').trParams({'count': '$m'});
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return (h == 1 ? 'hour_ago' : 'hours_ago').trParams({'count': '$h'});
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return (d == 1 ? 'day_ago' : 'days_ago').trParams({'count': '$d'});
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return (mo == 1 ? 'month_ago' : 'months_ago').trParams({'count': '$mo'});
    }
    final y = (diff.inDays / 365).floor();
    return (y == 1 ? 'year_ago' : 'years_ago').trParams({'count': '$y'});
  }

  factory MessageModel.fromApiJson(
    Map<String, dynamic> json, {
    required int? currentUserId,
  }) {
    final message = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : json;
    final senderId =
        _asInt(json['sender_id']) ??
        _asInt(message['sender_id']) ??
        _asInt(message['user_id']);
    final threadId = _asInt(message['thread_id']);
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final createdAt = message['created_at'] as String? ?? '';
    final type = (message['type'] ?? json['type'] ?? 'text').toString();
    final attachmentsRaw = message['attachments'] ?? json['attachments'];
    final attachments = _parseAttachments(attachmentsRaw);
    final locationRaw = message['location'] ?? json['location'];
    final location = _parseLocation(locationRaw);
    final call = _parseCall(message['call'] ?? json['call']);
    final priceIncreaseRequest = _parsePriceIncreaseRequest(
      message['price_increase_request'] ?? json['price_increase_request'],
    );
    final body =
        (message['body'] as String?) ?? (json['body'] as String?) ?? '';
    final previewText =
        (message['preview_text'] as String?) ??
        (json['preview_text'] as String?) ??
        _fallbackPreviewText(type: type, body: body, location: location);

    return MessageModel(
      id: _asInt(message['id']),
      threadId: threadId,
      userId: _asInt(message['user_id']) ?? senderId,
      sender:
          (user['name'] as String?) ?? (json['sender_name'] as String?) ?? '',
      senderAvatar:
          user['avatar']?.toString() ?? json['sender_avatar']?.toString(),
      text: body,
      type: type,
      previewText: previewText,
      attachments: attachments,
      location: location,
      call: call,
      priceIncreaseRequest: priceIncreaseRequest,
      isSender: currentUserId != null && senderId == currentUserId,
      sended: true,
      time: diffForHumans(createdAt),
      date: '',
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      threadId: json['threadId'] as int?,
      userId: _asInt(json['userId']),
      senderAvatar: json['senderAvatar'] as String?,
      text: json['text'] ?? '',
      type: json['type'] as String? ?? 'text',
      previewText: json['previewText'] as String?,
      attachments: _parseAttachments(json['attachments']),
      location: _parseLocation(json['location']),
      call: _parseCall(json['call']),
      priceIncreaseRequest: _parsePriceIncreaseRequest(json['priceIncreaseRequest']),
      isSender: json['isSender'] ?? false,
      sended: json['sended'] ?? false,
      time: json['time'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'userId': userId,
      'senderAvatar': senderAvatar,
      'text': text,
      'type': type,
      'previewText': previewText,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'location': location?.toJson(),
      'call': call?.toJson(),
      'priceIncreaseRequest': priceIncreaseRequest?.toJson(),
      'isSender': isSender,
      'sended': sended,
      'time': time,
      'date': date,
    };
  }

  static MessageLocationModel? _parseLocation(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MessageLocationModel.fromJson(value);
    }
    if (value is Map) {
      return MessageLocationModel.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return MessageLocationModel.fromJson(first);
      }
      if (first is Map) {
        return MessageLocationModel.fromJson(Map<String, dynamic>.from(first));
      }
    }
    return null;
  }

  static CallMessageSummary? _parseCall(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CallMessageSummary.fromJson(value);
    }
    if (value is Map) {
      return CallMessageSummary.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static PriceIncreaseRequestModel? _parsePriceIncreaseRequest(dynamic value) {
    if (value is Map) {
      return PriceIncreaseRequestModel.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static List<MessageAttachmentModel> _parseAttachments(dynamic value) {
    if (value is! List) return <MessageAttachmentModel>[];
    return value
        .whereType<Map>()
        .map((item) => MessageAttachmentModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _fallbackPreviewText({
    required String type,
    required String body,
    required MessageLocationModel? location,
  }) {
    if (body.isNotEmpty) return body;
    if (type == 'image') return '[Ảnh]';
    if (type == 'location') return location?.label ?? 'Vị trí hiện tại';
    if (type == 'call') return '[Cuộc gọi]';
    if (type == 'price_increase_request') return '[Yêu cầu tăng giá]';
    return '';
  }
}
