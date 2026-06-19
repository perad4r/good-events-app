class PartnerProfileModel {
  final int? id;
  final String? partnerName;

  PartnerProfileModel({this.id, this.partnerName});

  factory PartnerProfileModel.fromJson(Map<String, dynamic> json) {
    return PartnerProfileModel(
      id: json['id'] as int?,
      partnerName: json['partner_name'] as String?,
    );
  }
}

class PartnerStatisticsModel {
  final num? averageStars;
  final int? totalRatings;

  PartnerStatisticsModel({this.averageStars, this.totalRatings});

  factory PartnerStatisticsModel.fromJson(Map<String, dynamic> json) {
    return PartnerStatisticsModel(
      averageStars: json['average_stars'] as num?,
      totalRatings: json['total_ratings'] as int?,
    );
  }
}

class HistoryPartnerModel {
  final int? id;
  final String? avatarUrl;
  final String? name;
  final PartnerStatisticsModel? statistics;
  final PartnerProfileModel? partnerProfile;

  HistoryPartnerModel({
    this.id,
    this.avatarUrl,
    this.name,
    this.statistics,
    this.partnerProfile,
  });

  factory HistoryPartnerModel.fromJson(Map<String, dynamic> json) {
    return HistoryPartnerModel(
      id: json['id'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      name: json['name'] as String?,
      statistics: json['statistics'] != null
          ? PartnerStatisticsModel.fromJson(json['statistics'] as Map<String, dynamic>)
          : null,
      partnerProfile: json['partner_profile'] != null
          ? PartnerProfileModel.fromJson(json['partner_profile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HistoryReviewModel {
  final int? rating;
  final String? comment;
  final bool? recommend;

  HistoryReviewModel({this.rating, this.comment, this.recommend});

  factory HistoryReviewModel.fromJson(Map<String, dynamic> json) {
    return HistoryReviewModel(
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      recommend: json['recommend'] as bool?,
    );
  }
}

class HistoryOrderModel {
  final int id;
  final String? code;
  final String? address;
  final String? date;
  final String? startTime;
  final String? endTime;
  final num? total;
  final num? finalTotal;
  final String? note;
  final String? status;
  final String? updatedAt;
  final String? categoryName;
  final String? parentCategoryName;
  final String? categoryImage;
  final String? eventName;
  final String? arrivalPhoto;
  final HistoryPartnerModel? partner;
  final HistoryReviewModel? review;

  HistoryOrderModel({
    required this.id,
    this.code,
    this.address,
    this.date,
    this.startTime,
    this.endTime,
    this.total,
    this.finalTotal,
    this.note,
    this.status,
    this.updatedAt,
    this.categoryName,
    this.parentCategoryName,
    this.categoryImage,
    this.eventName,
    this.arrivalPhoto,
    this.partner,
    this.review,
  });

  factory HistoryOrderModel.fromJson(Map<String, dynamic> json) {
    return HistoryOrderModel(
      id: json['id'] as int,
      code: json['code'] as String?,
      address: json['address'] as String?,
      date: json['date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      total: json['total'] as num?,
      finalTotal: json['final_total'] as num?,
      note: json['note'] as String?,
      status: json['status'] as String?,
      updatedAt: json['updated_at'] as String?,
      categoryName: json['category_name'] as String?,
      parentCategoryName: json['parent_category_name'] as String?,
      categoryImage: json['category_image'] as String?,
      eventName: json['event_name'] as String?,
      arrivalPhoto: json['arrival_photo'] as String?,
      partner: json['partner'] != null
          ? HistoryPartnerModel.fromJson(json['partner'] as Map<String, dynamic>)
          : null,
      review: json['review'] != null
          ? HistoryReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
    );
  }
}
