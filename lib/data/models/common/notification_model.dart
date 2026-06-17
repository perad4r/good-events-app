class NotificationModel {
  final String id;
  final String title;
  final String message;
  bool unread;
  final DateTime createdAt;
  final int? orderId;
  final String? href;
  final Map<String, dynamic> payload;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.unread,
    required this.createdAt,
    this.orderId,
    this.href,
    this.payload = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map<String, dynamic>
        ? json['payload'] as Map<String, dynamic>
        : <String, dynamic>{};
    final href = json['href'] as String?;

    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      unread: json['unread'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      orderId: _extractOrderId(json, payload, href),
      href: href,
      payload: payload,
    );
  }

  static int? _extractOrderId(
    Map<String, dynamic> json,
    Map<String, dynamic> payload,
    String? href,
  ) {
    final directId =
        _toInt(json['order_id']) ??
        _toInt(json['bill_id']) ??
        _toInt(json['partner_bill_id']) ??
        _toInt(payload['order_id']) ??
        _toInt(payload['bill_id']) ??
        _toInt(payload['partner_bill_id']);
    if (directId != null) return directId;

    final actionUrl = href ?? _firstActionUrl(payload);
    if (actionUrl == null || actionUrl.isEmpty) return null;

    final uri = Uri.tryParse(actionUrl);
    final queryId = uri == null
        ? null
        : _toInt(uri.queryParameters['order']) ??
              _toInt(uri.queryParameters['order_id']) ??
              _toInt(uri.queryParameters['bill_id']) ??
              _toInt(uri.queryParameters['partner_bill_id']);
    if (queryId != null) return queryId;

    final match = RegExp(r'(?:orders?|bills?)/(\d+)').firstMatch(actionUrl);
    return _toInt(match?.group(1));
  }

  static String? _firstActionUrl(Map<String, dynamic> payload) {
    final actions = payload['actions'];
    if (actions is! List) return null;

    for (final action in actions) {
      if (action is Map && action['url'] != null) {
        return action['url'].toString();
      }
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
