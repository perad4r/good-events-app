import 'package:sukientotapp/core/utils/env_config.dart';

class PublicProfilePreviewModel {
  final String profileType;
  final PublicProfilePayloadModel payload;

  const PublicProfilePreviewModel({
    required this.profileType,
    required this.payload,
  });

  factory PublicProfilePreviewModel.fromJson(Map<String, dynamic> json) {
    return PublicProfilePreviewModel(
      profileType: json['profile_type'] as String? ?? '',
      payload: PublicProfilePayloadModel.fromJson(
        json['payload'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class PublicProfilePayloadModel {
  final PublicProfileUserModel user;
  final PublicProfileQuickModel quick;
  final PublicProfileContactModel? contact;
  final List<PublicProfileServiceModel> services;
  final List<PublicProfileReviewModel> reviews;
  final String intro;
  final String videoUrl;

  const PublicProfilePayloadModel({
    required this.user,
    required this.quick,
    required this.contact,
    required this.services,
    required this.reviews,
    required this.intro,
    required this.videoUrl,
  });

  factory PublicProfilePayloadModel.fromJson(Map<String, dynamic> json) {
    return PublicProfilePayloadModel(
      user: PublicProfileUserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      quick: PublicProfileQuickModel.fromJson(
        json['quick'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      contact: json['contact'] is Map<String, dynamic>
          ? PublicProfileContactModel.fromJson(
              json['contact'] as Map<String, dynamic>,
            )
          : null,
      services: (json['services'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PublicProfileServiceModel.fromJson)
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PublicProfileReviewModel.fromJson)
          .toList(),
      intro: json['intro'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
    );
  }

  String get introOrBio {
    if (_hasMeaningfulHtml(intro)) return intro;
    if (_hasMeaningfulHtml(user.bio)) return user.bio;
    return '';
  }

  bool get hasGallery => services.any((service) => service.images.isNotEmpty);

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  String get externalVideoUrl {
    final List<String> urls = _extractUrls(videoUrl);
    if (urls.isEmpty) return videoUrl;

    final String firstUrl = urls.first;
    final String? videoId = _extractVideoId(firstUrl);
    if (videoId != null) {
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    return firstUrl;
  }

  String get videoThumbnailUrl {
    final String? videoId = _extractVideoId(videoUrl);
    if (videoId == null) return '';
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}

class PublicProfileUserModel {
  final int id;
  final String name;
  final String avatarUrl;
  final String joinedYear;
  final String bio;
  final String emailVerifiedAt;
  final bool isVerified;
  final bool isLegit;

  const PublicProfileUserModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.joinedYear,
    required this.bio,
    required this.emailVerifiedAt,
    required this.isVerified,
    required this.isLegit,
  });

  factory PublicProfileUserModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      avatarUrl: _normalizeUrl(json['avatar_url'] as String? ?? ''),
      joinedYear: json['joined_year'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      emailVerifiedAt: json['email_verified_at'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      isLegit: json['is_legit'] as bool? ?? false,
    );
  }
}

class PublicProfileQuickModel {
  final int ordersPlaced;
  final int completedOrders;
  final String cancelledOrdersPct;
  final String lastActiveHuman;

  const PublicProfileQuickModel({
    required this.ordersPlaced,
    required this.completedOrders,
    required this.cancelledOrdersPct,
    required this.lastActiveHuman,
  });

  factory PublicProfileQuickModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileQuickModel(
      ordersPlaced: (json['orders_placed'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      cancelledOrdersPct: json['cancelled_orders_pct']?.toString() ?? '0',
      lastActiveHuman: json['last_active_human'] as String? ?? '',
    );
  }
}

class PublicProfileContactModel {
  final String phone;
  final String email;

  const PublicProfileContactModel({required this.phone, required this.email});

  factory PublicProfileContactModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileContactModel(
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  bool get hasData => phone.trim().isNotEmpty || email.trim().isNotEmpty;
}

class PublicProfileServiceModel {
  final int id;
  final int categoryId;
  final int userId;
  final String status;
  final List<String> images;
  final PublicProfileServiceCategoryModel? category;

  const PublicProfileServiceModel({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.status,
    required this.images,
    required this.category,
  });

  factory PublicProfileServiceModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileServiceModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic image) => _normalizeUrl(image?.toString() ?? ''))
          .where((String image) => image.isNotEmpty)
          .toList(),
      category: json['category'] is Map<String, dynamic>
          ? PublicProfileServiceCategoryModel.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String get name => category?.name ?? '';
}

class PublicProfileServiceCategoryModel {
  final int id;
  final String name;

  const PublicProfileServiceCategoryModel({
    required this.id,
    required this.name,
  });

  factory PublicProfileServiceCategoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PublicProfileServiceCategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class PublicProfileReviewModel {
  final int id;
  final String author;
  final int rating;
  final String review;
  final String createdHuman;

  const PublicProfileReviewModel({
    required this.id,
    required this.author,
    required this.rating,
    required this.review,
    required this.createdHuman,
  });

  factory PublicProfileReviewModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      author: json['author'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      review: json['review'] as String? ?? '',
      createdHuman: json['created_human'] as String? ?? '',
    );
  }
}

String _normalizeUrl(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) return trimmed;

  final String baseUrl = EnvConfig.apiBaseUrl.trim();
  final Uri? baseUri = Uri.tryParse(baseUrl);
  if (baseUri == null) return trimmed;

  return baseUri.resolve(trimmed).toString();
}

bool _hasMeaningfulHtml(String value) {
  final String plain = value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', '')
      .trim();
  return plain.isNotEmpty;
}

List<String> _extractUrls(String value) {
  final RegExp urlRegExp = RegExp(
    r'((?:\bhttps?:)?\/\/[^,\s()<>]+(?:\(\w+\)|(?:[a-zA-Z0-9]|\/)))',
    dotAll: true,
  );

  return urlRegExp
      .allMatches(value)
      .map((Match match) => match.group(0) ?? '')
      .where((String url) => url.isNotEmpty)
      .toList();
}

String? _extractVideoId(String value) {
  if (value.isEmpty) return null;

  final RegExp regExp = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|embed\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );
  final RegExpMatch? match = regExp.firstMatch(value);
  return match?.group(1);
}
