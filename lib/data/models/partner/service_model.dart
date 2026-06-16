class ServiceModel {
  final String id;
  final String status;
  final String category;
  final String categoryId;

  ServiceModel({
    required this.id,
    required this.status,
    required this.category,
    required this.categoryId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      status: json['status'] as String,
      category: json['category'] as String,
      categoryId: json['category_id'] as String? ?? '',
    );
  }

  bool get isEditable => status == 'pending' || status == 'rejected';
}

class ServiceMediaModel {
  final String id;
  final String name;
  final String url;
  final String description;

  ServiceMediaModel({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
  });

  factory ServiceMediaModel.fromJson(Map<String, dynamic> json) {
    return ServiceMediaModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class ServiceDetailModel {
  final String id;
  final String status;
  final String category;
  final String categoryId;
  final List<ServiceMediaModel> serviceMedia;

  ServiceDetailModel({
    required this.id,
    required this.status,
    required this.category,
    required this.categoryId,
    required this.serviceMedia,
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['service_media'] as List<dynamic>? ?? [];
    return ServiceDetailModel(
      id: json['id'] as String,
      status: json['status'] as String,
      category: json['category'] as String,
      categoryId: json['category_id'] as String? ?? '',
      serviceMedia: rawMedia
          .map((m) => ServiceMediaModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServiceCategoryModel {
  final String id;
  final String name;

  ServiceCategoryModel({required this.id, required this.name});

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }
}

class ServiceImageModel {
  final String id;
  final String url;
  final String thumb;
  final String fileName;
  final int size;

  ServiceImageModel({
    required this.id,
    required this.url,
    required this.thumb,
    required this.fileName,
    required this.size,
  });

  String get previewUrl => url.isNotEmpty ? url : thumb;

  factory ServiceImageModel.fromJson(Map<String, dynamic> json) {
    return ServiceImageModel(
      id: json['id'].toString(),
      url: json['url'] as String? ?? '',
      thumb: json['thumb'] as String? ?? json['thumbnail'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}
