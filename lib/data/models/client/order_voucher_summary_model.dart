class OrderVoucherSummaryModel {
  final int id;
  final String code;

  const OrderVoucherSummaryModel({
    required this.id,
    required this.code,
  });

  factory OrderVoucherSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderVoucherSummaryModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
    );
  }
}
