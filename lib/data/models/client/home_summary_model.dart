class HomeSummaryModel {
  final bool isHasNewNoti;
  final AppNotification? notification;
  final int pendingOrders;
  final int confirmedOrders;
  final int pendingPartners; // Applicants
  final List<String> pendingPartnerAvatars;

  const HomeSummaryModel({
    required this.isHasNewNoti,
    this.notification,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.pendingPartners,
    required this.pendingPartnerAvatars,
  });

  HomeSummaryModel copyWith({
    bool? isHasNewNoti,
    AppNotification? notification,
    int? pendingOrders,
    int? confirmedOrders,
    int? pendingPartners,
    List<String>? pendingPartnerAvatars,
  }) {
    return HomeSummaryModel(
      isHasNewNoti: isHasNewNoti ?? this.isHasNewNoti,
      notification: notification ?? this.notification,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      confirmedOrders: confirmedOrders ?? this.confirmedOrders,
      pendingPartners: pendingPartners ?? this.pendingPartners,
      pendingPartnerAvatars:
          pendingPartnerAvatars ?? this.pendingPartnerAvatars,
    );
  }

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return HomeSummaryModel(
      isHasNewNoti: json['is_has_new_noti'] ?? false,
      notification: json['app_notification'] != null
          ? AppNotification.fromJson(
              Map<String, dynamic>.from(json['app_notification']),
            )
          : null,
      pendingOrders: _parseInt(json['pending_orders']),
      confirmedOrders: _parseInt(json['confirmed_orders']),
      pendingPartners: _parseInt(json['pending_partners']),
      pendingPartnerAvatars: List<String>.from(
        json['pending_partner_avatars'] ?? [],
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AppNotification {
  final String? type;
  final String? notificationImageUrl;
  final String? title;
  final String? content;
  final String? imageUrl;

  const AppNotification({
    this.type,
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      type: json['type'] ?? '',
      notificationImageUrl: json['notification_image'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image'] ?? '',
    );
  }
}
