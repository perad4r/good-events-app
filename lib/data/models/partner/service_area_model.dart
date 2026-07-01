class PartnerServiceAreaModel {
  final int id;
  final String name;
  final int provinceId;
  final String provinceName;

  const PartnerServiceAreaModel({
    required this.id,
    required this.name,
    required this.provinceId,
    required this.provinceName,
  });

  factory PartnerServiceAreaModel.fromJson(Map<String, dynamic> json) {
    return PartnerServiceAreaModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      provinceId: json['province_id'] as int? ?? 0,
      provinceName: json['province_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province_id': provinceId,
      'province_name': provinceName,
    };
  }
}

class PartnerServiceAreasResponse {
  final List<int> serviceAreaLocationIds;
  final List<PartnerServiceAreaModel> serviceAreas;
  final bool success;

  const PartnerServiceAreasResponse({
    required this.serviceAreaLocationIds,
    required this.serviceAreas,
    this.success = false,
  });

  factory PartnerServiceAreasResponse.fromJson(Map<String, dynamic> json) {
    final ids = json['service_area_location_ids'] as List<dynamic>? ?? [];
    final areas = json['service_areas'] as List<dynamic>? ?? [];

    return PartnerServiceAreasResponse(
      success: json['success'] as bool? ?? false,
      serviceAreaLocationIds: ids.map((id) => (id as num).toInt()).toList(),
      serviceAreas: areas
          .map(
            (item) => PartnerServiceAreaModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
