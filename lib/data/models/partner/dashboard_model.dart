// ignore_from_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class DashboardModel {
  final String avatarUrl;
  final int balance;
  final int revenue;
  final List<int> quarterlyRevenue;
  final PartnerAppNotification? appNotification;

  DashboardModel({
    required this.avatarUrl,
    required this.balance,
    required this.revenue,
    required this.quarterlyRevenue,
    this.appNotification,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'avatar_url': avatarUrl,
      'balance': balance,
      'revenue': revenue,
      'quarterly_revenue': quarterlyRevenue,
      'app_notification': appNotification?.toMap(),
    };
  }

  factory DashboardModel.fromMap(Map<String, dynamic> map) {
    return DashboardModel(
      avatarUrl: map['avatar_url'] ?? '',
      balance: map['wallet_balance'],
      revenue: map['revenue'],
      quarterlyRevenue:
          (map['quarterly_revenue'] as List<dynamic>?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
      appNotification: map['app_notification'] is Map
          ? PartnerAppNotification.fromMap(
              Map<String, dynamic>.from(map['app_notification']),
            )
          : null,
    );
  }

  static Map<String, String> _parseAvatars(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    if (value is List) {
      return {};
    }
    return {};
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String toJson() => json.encode(toMap());

  factory DashboardModel.fromJson(String source) =>
      DashboardModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PartnerAppNotification {
  final String type;
  final String? notificationImageUrl;
  final String? title;
  final String? content;
  final String? imageUrl;

  const PartnerAppNotification({
    required this.type,
    this.notificationImageUrl,
    this.title,
    this.content,
    this.imageUrl,
  });

  bool get hasTitle => (title ?? '').trim().isNotEmpty;
  bool get hasContent => (content ?? '').trim().isNotEmpty;
  bool get hasNotificationImage =>
      (notificationImageUrl ?? '').trim().isNotEmpty;
  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;
  bool get hasText => hasTitle || hasContent;
  bool get canDisplay {
    return switch (type) {
      'image_only' => hasNotificationImage,
      'text_only' => hasText,
      'text_and_image' => hasText || hasImage,
      _ => hasText || hasNotificationImage || hasImage,
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'notification_image': notificationImageUrl,
      'title': title,
      'content': content,
      'image': imageUrl,
    };
  }

  factory PartnerAppNotification.fromMap(Map<String, dynamic> map) {
    return PartnerAppNotification(
      type: (map['type'] ?? '').toString(),
      notificationImageUrl: _parseNullableString(map['notification_image']),
      title: _parseNullableString(map['title']),
      content: _parseNullableString(map['content']),
      imageUrl: _parseNullableString(map['image']),
    );
  }

  static String? _parseNullableString(dynamic value) {
    final parsedValue = value?.toString().trim();
    if (parsedValue == null || parsedValue.isEmpty) return null;
    return parsedValue;
  }
}
