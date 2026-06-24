class OrderPartnerProfileModel {
  final int id;
  final int userId;
  final String partnerName;
  final String identityCardNumber;
  final bool isLegit;
  final int locationId;
  final String createdAt;
  final String updatedAt;

  OrderPartnerProfileModel({
    required this.id,
    required this.userId,
    required this.partnerName,
    required this.identityCardNumber,
    required this.isLegit,
    required this.locationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderPartnerProfileModel.fromJson(Map<String, dynamic> json) {
    return OrderPartnerProfileModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      partnerName: json['partner_name'] as String? ?? '',
      identityCardNumber: json['identity_card_number'] as String? ?? '',
      isLegit: json['is_legit'] as bool? ?? false,
      locationId: json['location_id'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class OrderPartnerModel {
  final int id;
  final String name;
  final String avatar;
  final OrderPartnerProfileModel? partnerProfile;

  OrderPartnerModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.partnerProfile,
  });

  factory OrderPartnerModel.fromJson(Map<String, dynamic> json) {
    return OrderPartnerModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      partnerProfile: json['partner_profile'] != null
          ? OrderPartnerProfileModel.fromJson(json['partner_profile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderItemModel {
  final int id;
  final int partnerBillId;
  final int partnerId;
  final double total;
  final String status;
  final OrderPartnerModel? partner;

  OrderItemModel({
    required this.id,
    required this.partnerBillId,
    required this.partnerId,
    required this.total,
    required this.status,
    this.partner,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      partnerBillId: json['partner_bill_id'] as int? ?? 0,
      partnerId: json['partner_id'] as int? ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'new',
      partner: json['partner'] != null
          ? OrderPartnerModel.fromJson(json['partner'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderDetailModel {
  final int billId;
  final List<OrderItemModel> items;

  OrderDetailModel({
    required this.billId,
    required this.items,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      billId: json['bill_id'] as int? ?? 0,
      items: (json['items'] as List?)?.map((item) => OrderItemModel.fromJson(item)).toList() ?? [],
    );
  }
}
