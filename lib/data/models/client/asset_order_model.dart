class AssetOrderCategory {
  final int id;
  final String name;
  final String slug;

  const AssetOrderCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory AssetOrderCategory.fromJson(Map<String, dynamic> json) {
    return AssetOrderCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class AssetOrderFileProduct {
  final int id;
  final String name;
  final String slug;
  final double price;
  final String? image;
  final AssetOrderCategory? category;

  const AssetOrderFileProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.image,
    this.category,
  });

  factory AssetOrderFileProduct.fromJson(Map<String, dynamic> json) {
    return AssetOrderFileProduct(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      image: json['image'] as String?,
      category: json['category'] != null
          ? AssetOrderCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AssetOrderModel {
  final int id;
  final int fileProductId;
  final int clientId;
  final double total;
  final double? tax;
  final double? finalTotal;
  final String status;
  final String statusLabel;
  final String paymentMethod;
  final String createdAt;
  final String updatedAt;
  final String? arrivalPhoto;
  final String? completionPhoto;
  final bool canRepay;
  final bool canDownload;
  final AssetOrderFileProduct? fileProduct;

  const AssetOrderModel({
    required this.id,
    required this.fileProductId,
    required this.clientId,
    required this.total,
    this.tax,
    this.finalTotal,
    required this.status,
    required this.statusLabel,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.arrivalPhoto,
    this.completionPhoto,
    required this.canRepay,
    required this.canDownload,
    this.fileProduct,
  });

  factory AssetOrderModel.fromJson(Map<String, dynamic> json) {
    return AssetOrderModel(
      id: json['id'] as int? ?? 0,
      fileProductId: json['file_product_id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      tax: json['tax'] != null ? double.tryParse(json['tax'].toString()) : null,
      finalTotal: json['final_total'] != null
          ? double.tryParse(json['final_total'].toString())
          : null,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      arrivalPhoto: json['arrival_photo'] as String?,
      completionPhoto: json['completion_photo'] as String?,
      canRepay: json['can_repay'] as bool? ?? false,
      canDownload: json['can_download'] as bool? ?? false,
      fileProduct: json['file_product'] != null
          ? AssetOrderFileProduct.fromJson(json['file_product'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convenience getters matching old AssetOrder interface
  String get productName => fileProduct?.name ?? '';
  String get categoryName => fileProduct?.category?.name ?? '';
  String? get thumbnail => fileProduct?.image;
  double get effectiveTotal => finalTotal ?? total;
}
