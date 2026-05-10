class ReportModel {
  final int id;
  final int reportedUserId;
  final int reporterUserId;
  final String title;
  final String description;

  ReportModel({
    required this.id,
    required this.reportedUserId,
    required this.reporterUserId,
    required this.title,
    required this.description,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int? ?? 0,
      reportedUserId: json['reported_user_id'] as int? ?? 0,
      reporterUserId: json['reporter_user_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reported_user_id': reportedUserId,
      'reporter_user_id': reporterUserId,
      'title': title,
      'description': description,
    };
  }
}
