class AccessoryModel {
  final int id;
  final int? accessoryId;
  final String name;

  const AccessoryModel({
    required this.id,
    required this.name,
    this.accessoryId,
  });

  factory AccessoryModel.fromJson(Map<String, dynamic> json) {
    return AccessoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      accessoryId: (json['accessory_id'] as num?)?.toInt(),
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  static List<AccessoryModel> listFromJson(dynamic value) {
    if (value is! List) return const <AccessoryModel>[];

    return value
        .whereType<Map>()
        .map((item) => AccessoryModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0 && item.name.isNotEmpty)
        .toList(growable: false);
  }
}
