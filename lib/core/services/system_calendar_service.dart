import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/data/models/partner/show_bill_model.dart';

class CalendarSyncResult {
  final int synced;
  final int skipped;
  final bool permissionGranted;

  const CalendarSyncResult({
    required this.synced,
    required this.skipped,
    required this.permissionGranted,
  });
}

class SystemCalendarService {
  static const String _eventIdPrefix = 'system_calendar_event_';
  static final DeviceCalendar _calendar = DeviceCalendar.instance;

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> shouldShowPermissionExplanation() async {
    if (!_isSupported) return false;
    try {
      return await _calendar.hasPermissions() !=
          CalendarPermissionStatus.granted;
    } catch (error) {
      logger.w('[Calendar] Unable to read permission status: $error');
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      final status = await _calendar.requestPermissions();
      final granted = status == CalendarPermissionStatus.granted;
      logger.i('[Calendar] Permission status: $status');
      return granted;
    } catch (error, stackTrace) {
      logger.e(
        '[Calendar] Unable to request permission.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<CalendarSyncResult> syncBills(
    Iterable<ShowBill> bills, {
    bool requestPermission = true,
  }) async {
    var synced = 0;
    var skipped = 0;
    final granted = await _ensurePermission(requestPermission: requestPermission);
    if (!granted) {
      return CalendarSyncResult(
        synced: 0,
        skipped: bills.length,
        permissionGranted: false,
      );
    }

    for (final bill in bills) {
      if (await syncNotificationData(bill.toCalendarData())) {
        synced++;
      } else {
        skipped++;
      }
    }
    return CalendarSyncResult(
      synced: synced,
      skipped: skipped,
      permissionGranted: true,
    );
  }

  static Future<bool> syncNotificationData(
    Map<String, dynamic> data, {
    bool requestPermission = false,
  }) async {
    if (data['code']?.toString() != 'BILL_CONFIRMED') return false;
    if (!await _ensurePermission(requestPermission: requestPermission)) {
      logger.w('[Calendar] BILL_CONFIRMED ignored because permission is missing.');
      return false;
    }

    final billId = data['bill_id']?.toString().trim() ?? '';
    final start = _parseDateTime(data['date'], data['start_time']);
    final parsedEnd = _parseDateTime(data['date'], data['end_time']);
    if (billId.isEmpty || start == null || parsedEnd == null) {
      logger.w('[Calendar] BILL_CONFIRMED has invalid date/time data: $data');
      return false;
    }
    final end = parsedEnd.isAfter(start)
        ? parsedEnd
        : parsedEnd.add(const Duration(days: 1));
    final eventName = data['event']?.toString().trim() ?? '';
    final category = data['category']?.toString().trim() ?? '';
    final client = data['client']?.toString().trim() ?? '';
    final partner = data['partner']?.toString().trim() ?? '';
    final calendarOwner = data['calendar_owner']?.toString().trim() == 'client'
        ? 'client'
        : 'partner';
    final titleParts = <String>[
      if (eventName.isNotEmpty) eventName,
      if (category.isNotEmpty) category,
    ];
    final title = titleParts.isEmpty
        ? 'Sự kiện #$billId'
        : titleParts.join(' - ');
    final description = <String>[
      if (partner.isNotEmpty) 'Đối tác: $partner',
      if (partner.isEmpty && client.isNotEmpty) 'Khách hàng: $client',
      'Mã đơn: $billId',
      'Nguồn: Sự Kiện Tốt',
    ].join('\n');
    final location = data['address']?.toString().trim() ?? '';

    try {
      final storage = GetStorage();
      final storageKey = '$_eventIdPrefix${calendarOwner}_$billId';
      final existingEventId = storage.read<String>(storageKey);
      if (existingEventId != null && existingEventId.isNotEmpty) {
        final existingEvent = await _calendar.getEvent(existingEventId);
        if (existingEvent != null) {
          await _calendar.updateEvent(
            eventId: existingEventId,
            title: title,
            startDate: start,
            endDate: end,
            description: Patch.set(description),
            location: location.isEmpty ? const Patch.clear() : Patch.set(location),
            reminders: Patch.set(const <Duration>[Duration(minutes: 60)]),
          );
          logger.i('[Calendar] Updated bill $billId in the system calendar.');
          return true;
        }
      }

      final eventId = await _calendar.createEvent(
        title: title,
        startDate: start,
        endDate: end,
        description: description,
        location: location.isEmpty ? null : location,
        reminders: const <Duration>[Duration(minutes: 60)],
      );
      await storage.write(storageKey, eventId);
      logger.i('[Calendar] Added bill $billId to the system calendar.');
      return true;
    } catch (error, stackTrace) {
      logger.e(
        '[Calendar] Failed to sync bill $billId.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<bool> _ensurePermission({required bool requestPermission}) async {
    if (!_isSupported) return false;
    try {
      var status = await _calendar.hasPermissions();
      if (status == CalendarPermissionStatus.notDetermined && requestPermission) {
        status = await _calendar.requestPermissions();
      }
      return status == CalendarPermissionStatus.granted;
    } catch (error) {
      logger.w('[Calendar] Permission check failed: $error');
      return false;
    }
  }

  static DateTime? _parseDateTime(Object? dateValue, Object? timeValue) {
    final date = dateValue?.toString().trim() ?? '';
    final time = timeValue?.toString().trim() ?? '';
    if (date.isEmpty || time.isEmpty) return null;
    return DateTime.tryParse('${date}T$time');
  }
}

extension ShowBillCalendarData on ShowBill {
  Map<String, dynamic> toCalendarData() => <String, dynamic>{
    'code': 'BILL_CONFIRMED',
    'bill_id': id.toString(),
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'address': address,
    'client': clientName,
    'event': event,
    'category': category,
    'calendar_owner': 'partner',
  };
}
