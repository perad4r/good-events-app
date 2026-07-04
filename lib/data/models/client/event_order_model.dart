import 'package:sukientotapp/data/models/client/order_voucher_summary_model.dart';

class EventOrderModel {
  final int id;
  final String code;
  final String address;
  final String date;
  final String startTime;
  final String endTime;
  final double? finalTotal;
  final String? arrivalPhoto;
  final String? completionPhoto;
  final String note;
  final String status;
  final int threadId;
  final String categoryName;
  final String parentCategoryName;
  final String categoryImage;
  final String eventName;
  final int applicantCount;
  final List<String> bookingPhotos;
  final OrderVoucherSummaryModel? voucher;

  EventOrderModel({
    required this.id,
    required this.code,
    required this.address,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.finalTotal,
    required this.arrivalPhoto,
    required this.completionPhoto,
    required this.note,
    required this.status,
    required this.threadId,
    required this.categoryName,
    required this.parentCategoryName,
    required this.categoryImage,
    required this.eventName,
    required this.applicantCount,
    required this.bookingPhotos,
    this.voucher,
  });

  factory EventOrderModel.fromJson(Map<String, dynamic> json) {
    return EventOrderModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      finalTotal: json['final_total'] != null
          ? double.tryParse(json['final_total'].toString())
          : null,
      arrivalPhoto: json['arrival_photo'] as String? ?? '',
      completionPhoto: json['completion_photo'] as String? ?? '',
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? '',
      threadId: json['thread_id'] as int? ?? 0,
      categoryName: (json['category_name'] as String? ?? '').trim(),
      parentCategoryName: (json['parent_category_name'] as String? ?? '').trim(),
      categoryImage: json['category_image'] as String? ?? '',
      eventName: (json['event_name'] as String? ?? '').trim(),
      applicantCount: json['applicant_count'] as int? ?? 0,
      bookingPhotos: _parseBookingPhotos(json['booking_photos']),
      voucher: json['voucher'] is Map<String, dynamic>
          ? OrderVoucherSummaryModel.fromJson(
              json['voucher'] as Map<String, dynamic>,
            )
          : null,
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
