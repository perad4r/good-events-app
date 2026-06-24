// ignore_from_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class DashboardModel {
  final String avatarUrl;
  final int balance;
  final int revenue;
  final int recentReviewsCount;
  final Map<String, String> recentReviewsAvatars;
  final List<int> quarterlyRevenue;

  DashboardModel({
    required this.avatarUrl,
    required this.balance,
    required this.revenue,
    required this.recentReviewsCount,
    required this.recentReviewsAvatars,
    required this.quarterlyRevenue,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'avatar_url': avatarUrl,
      'balance': balance,
      'revenue': revenue,
      'recent_reviews_count': recentReviewsCount,
      'recent_reviews_avatars': recentReviewsAvatars,
      'quarterly_revenue': quarterlyRevenue,
    };
  }

  factory DashboardModel.fromMap(Map<String, dynamic> map) {
    return DashboardModel(
      avatarUrl: map['avatar_url'] ?? '',
      balance: map['wallet_balance'],
      revenue: map['revenue'],
      recentReviewsCount: map['recent_reviews_count'],
      recentReviewsAvatars: _parseAvatars(map['recent_reviews_avatars']),
      quarterlyRevenue:
          (map['quarterly_revenue'] as List<dynamic>?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
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
