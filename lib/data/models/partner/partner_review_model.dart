class PartnerReviewsPageModel {
  final List<PartnerReviewItemModel> reviews;
  final PartnerReviewsMetaModel meta;

  const PartnerReviewsPageModel({
    required this.reviews,
    required this.meta,
  });

  factory PartnerReviewsPageModel.fromMap(Map<String, dynamic> map) {
    final reviewsMap = map['reviews'] as Map<String, dynamic>? ?? const {};
    final data = reviewsMap['data'] as List<dynamic>? ?? const [];
    final metaMap = reviewsMap['meta'] as Map<String, dynamic>? ?? const {};

    return PartnerReviewsPageModel(
      reviews: data
          .whereType<Map<String, dynamic>>()
          .map(PartnerReviewItemModel.fromMap)
          .toList(),
      meta: PartnerReviewsMetaModel.fromMap(metaMap),
    );
  }
}

class PartnerReviewsMetaModel {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PartnerReviewsMetaModel({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PartnerReviewsMetaModel.fromMap(Map<String, dynamic> map) {
    return PartnerReviewsMetaModel(
      currentPage: _asInt(map['current_page'], fallback: 1),
      perPage: _asInt(map['per_page'], fallback: 10),
      total: _asInt(map['total']),
      lastPage: _asInt(map['last_page'], fallback: 1),
    );
  }
}

class PartnerReviewItemModel {
  final PartnerReviewBillModel bill;
  final PartnerReviewUserModel user;
  final PartnerReviewDetailModel review;

  const PartnerReviewItemModel({
    required this.bill,
    required this.user,
    required this.review,
  });

  factory PartnerReviewItemModel.fromMap(Map<String, dynamic> map) {
    return PartnerReviewItemModel(
      bill: PartnerReviewBillModel.fromMap(
        map['bill'] as Map<String, dynamic>? ?? const {},
      ),
      user: PartnerReviewUserModel.fromMap(
        map['user'] as Map<String, dynamic>? ?? const {},
      ),
      review: PartnerReviewDetailModel.fromMap(
        map['review'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PartnerReviewBillModel {
  final int id;
  final String code;
  final String category;
  final String event;
  final String date;
  final int finalTotal;

  const PartnerReviewBillModel({
    required this.id,
    required this.code,
    required this.category,
    required this.event,
    required this.date,
    required this.finalTotal,
  });

  factory PartnerReviewBillModel.fromMap(Map<String, dynamic> map) {
    return PartnerReviewBillModel(
      id: _asInt(map['id']),
      code: map['code'] as String? ?? '',
      category: map['category'] as String? ?? '',
      event: map['event'] as String? ?? '',
      date: map['date'] as String? ?? '',
      finalTotal: _asInt(map['final_total']),
    );
  }
}

class PartnerReviewUserModel {
  final int id;
  final String name;

  const PartnerReviewUserModel({
    required this.id,
    required this.name,
  });

  factory PartnerReviewUserModel.fromMap(Map<String, dynamic> map) {
    return PartnerReviewUserModel(
      id: _asInt(map['id']),
      name: map['name'] as String? ?? '',
    );
  }
}

class PartnerReviewDetailModel {
  final int id;
  final int rating;
  final Map<String, int> ratings;
  final String comment;
  final bool recommend;
  final String createdAt;

  const PartnerReviewDetailModel({
    required this.id,
    required this.rating,
    required this.ratings,
    required this.comment,
    required this.recommend,
    required this.createdAt,
  });

  factory PartnerReviewDetailModel.fromMap(Map<String, dynamic> map) {
    final ratingsMap = map['ratings'] as Map<String, dynamic>? ?? const {};

    return PartnerReviewDetailModel(
      id: _asInt(map['id']),
      rating: _asInt(map['rating']),
      ratings: ratingsMap.map(
        (key, value) => MapEntry(key, _asInt(value)),
      ),
      comment: map['comment'] as String? ?? '',
      recommend: map['recommend'] == true,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
