import 'package:flutter/cupertino.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import '../booking_header.dart';
import '../booking_fields.dart';
import '../booking_layout.dart';

class BookingTimeStage extends GetView<ClientBookingController> {
  const BookingTimeStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingHeader(
          icon: FIcons.calendarDays,
          title: 'booking_stage_time_title'.tr,
          subtitle: 'booking_stage_time_subtitle'.tr,
        ),
        const SizedBox(height: 24),
        BookingTwoColumnRow(
          left: Obx(
            () => BookingSelectField(
              label: 'booking_start_time'.tr,
              value: controller.selectedStartTime.value,
              placeholder: 'booking_time_placeholder'.tr,
              leading: FIcons.clock,
              errorText: controller.fieldErrors['startTime'],
              onTap: () => _showTimePicker(
                context,
                title: 'booking_start_time'.tr,
                initialValue: controller.selectedStartTime.value,
                onSelect: controller.selectStartTime,
              ),
            ),
          ),
          right: Obx(
            () => BookingSelectField(
              label: 'booking_end_time'.tr,
              value: controller.selectedEndTime.value,
              placeholder: 'booking_time_placeholder'.tr,
              leading: FIcons.clock,
              errorText: controller.fieldErrors['endTime'],
              onTap: () => _showTimePicker(
                context,
                title: 'booking_end_time'.tr,
                initialValue: controller.selectedEndTime.value,
                onSelect: controller.selectEndTime,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => BookingSelectField(
            label: 'booking_event_date'.tr,
            value: controller.selectedEventDate.value,
            placeholder: 'booking_date_placeholder'.tr,
            leading: FIcons.calendar,
            errorText: controller.fieldErrors['eventDate'],
            onTap: () => _pickDate(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.selectEventDate(picked);
    }
  }

  void _showTimePicker(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSelect,
  }) {
    final DateTime now = DateTime.now();
    final DateTime initialTime = _parseTime(initialValue, now);
    DateTime selected = initialTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FTappable(
                        onPress: () => Get.back(),
                        child: Text(
                          'cancel'.tr,
                          style: context.typography.base,
                        ),
                      ),
                      Text(
                        title,
                        style: context.typography.base.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FTappable(
                        onPress: () {
                          onSelect(_formatTime(selected));
                          Get.back();
                        },
                        child: Text(
                          'done'.tr,
                          style: context.typography.base.copyWith(
                            color: context.fTheme.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialTime,
                    use24hFormat: true,
                    onDateTimeChanged: (value) {
                      selected = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime _parseTime(String value, DateTime fallback) {
    if (value.trim().isEmpty) return fallback;
    try {
      final parsed = DateFormat('HH:mm').parseStrict(value);
      return DateTime(
        fallback.year,
        fallback.month,
        fallback.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return fallback;
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}
