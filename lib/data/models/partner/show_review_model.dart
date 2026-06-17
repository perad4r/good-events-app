class ShowReview {
  const ShowReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.recommend,
    required this.createdAt,
  });

  final int id;
  final int rating;
  final String comment;
  final bool recommend;
  final String createdAt;

  factory ShowReview.fromMap(Map<String, dynamic> map) {
    return ShowReview(
      id: (map['id'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      recommend: map['recommend'] == true,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
