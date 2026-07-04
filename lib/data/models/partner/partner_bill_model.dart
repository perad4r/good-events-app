class PartnerBill {
  final int id;
  final String code;
  final double? finalTotal;
  final String createdAt;
  final String clientName;
  final String categoryName;
  final String categoryImage;
  final String eventName;
  final String date;
  final String startTime;
  final String endTime;
  final String address;
  final String? note;
  final List<String> bookingPhotos;

  const PartnerBill({
    required this.id,
    required this.code,
    this.finalTotal,
    required this.createdAt,
    required this.clientName,
    required this.categoryImage,
    required this.categoryName,
    required this.eventName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.address,
    this.note,
    this.bookingPhotos = const <String>[],
  });

  factory PartnerBill.fromMap(Map<String, dynamic> map) {
    return PartnerBill(
      id: map['id'] as int,
      code: map['code'] as String,
      finalTotal: map['final_total'] != null
          ? (map['final_total'] as num).toDouble()
          : null,
      createdAt: map['created_at'] as String,
      clientName: map['client_name'] as String,
      categoryName: map['category_name'] as String,
      categoryImage: map['category_image'] as String,
      eventName: map['event_name'] as String,
      date: map['date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      address: map['address'] as String,
      note: map['note'] as String?,
      bookingPhotos: _parseBookingPhotos(map['booking_photos']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'final_total': finalTotal,
      'created_at': createdAt,
      'client_name': clientName,
      'category_name': categoryName,
      'category_image': categoryImage,
      'event_name': eventName,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'address': address,
      'note': note,
      'booking_photos': bookingPhotos,
    };
  }

  static List<String> _parseBookingPhotos(dynamic value) {
    if (value is! List) return const <String>[];

    return value
        .map((photo) => photo?.toString().trim() ?? '')
        .where((photo) => photo.isNotEmpty)
        .take(5)
        .toList(growable: false);
  }
}

class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PaginationMeta.fromMap(Map<String, dynamic> map) {
    return PaginationMeta(
      currentPage: map['current_page'] as int,
      perPage: map['per_page'] as int,
      total: map['total'] as int,
      lastPage: map['last_page'] as int,
    );
  }
}

class RealtimePaginationMeta {
  final int currentPage;
  final int perPage;

  const RealtimePaginationMeta({
    required this.currentPage,
    required this.perPage,
  });

  factory RealtimePaginationMeta.fromMap(Map<String, dynamic> map) {
    return RealtimePaginationMeta(
      currentPage: map['current_page'] as int,
      perPage: map['per_page'] as int,
    );
  }
}

class RealtimeBillsResponse {
  final List<PartnerBill> partnerBills;
  final List<String> broadcastChannels;
  final String lastUpdated;
  final RealtimePaginationMeta meta;

  const RealtimeBillsResponse({
    required this.partnerBills,
    required this.broadcastChannels,
    required this.lastUpdated,
    required this.meta,
  });

  factory RealtimeBillsResponse.fromMap(Map<String, dynamic> map) {
    final partnerBillsRaw = map['partner_bills'] as Map<String, dynamic>;
    return RealtimeBillsResponse(
      partnerBills: (partnerBillsRaw['data'] as List<dynamic>)
          .map((e) => PartnerBill.fromMap(e as Map<String, dynamic>))
          .toList(),
      broadcastChannels: (map['broadcast_channels'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((channel) => channel.isNotEmpty)
          .toList(),
      lastUpdated: map['last_updated'] as String,
      meta: RealtimePaginationMeta.fromMap(
        partnerBillsRaw['meta'] as Map<String, dynamic>,
      ),
    );
  }
}
