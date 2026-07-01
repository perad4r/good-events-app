import 'package:sukientotapp/data/models/partner/partner_bill_model.dart';

class ShowBill {
  final int id;
  final String code;
  final String category;
  final String clientName;
  final String date;
  final String startTime;
  final String endTime;
  final String address;
  final int finalTotal;
  final String updatedAt;

  final String event;
  final String status;
  final String? note;
  final int? threadId;
  final List<String> bookingPhotos;

  final bool? isReviewed;

  const ShowBill({
    required this.id,
    required this.code,
    required this.category,
    required this.clientName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.finalTotal,
    required this.updatedAt,

    required this.event,
    required this.status,
    this.note,
    this.threadId,
    this.bookingPhotos = const <String>[],

    this.isReviewed,
  });

  ShowBill copyWith({String? status, bool? isReviewed}) {
    return ShowBill(
      id: id,
      code: code,
      category: category,
      clientName: clientName,
      date: date,
      startTime: startTime,
      endTime: endTime,
      address: address,
      finalTotal: finalTotal,
      updatedAt: updatedAt,
      event: event,
      status: status ?? this.status,
      note: note,
      threadId: threadId,
      bookingPhotos: bookingPhotos,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  factory ShowBill.fromMap(Map<String, dynamic> map) {
    return ShowBill(
      id: map['id'] as int,
      code: map['code'] as String,
      category: map['category'] as String,
      clientName: map['client_name'] as String,
      date: map['date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      address: map['address'] as String,
      finalTotal: map['final_total'] as int,
      updatedAt: map['updated_at'] as String,

      status: map['status'] as String,
      note: map['note'] as String?,
      threadId: map['thread_id'] as int?,
      event: map['event'] as String,
      bookingPhotos: _parseBookingPhotos(map['booking_photos']),
      isReviewed: map['review_exists'] == true,
    );
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

class ShowBillsResponse {
  final List<ShowBill> bills;
  final PaginationMeta meta;

  const ShowBillsResponse({required this.bills, required this.meta});

  factory ShowBillsResponse.fromMap(Map<String, dynamic> map) {
    return ShowBillsResponse(
      bills: (map['data'] as List<dynamic>)
          .map((e) => ShowBill.fromMap(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromMap(map['meta'] as Map<String, dynamic>),
    );
  }
}
