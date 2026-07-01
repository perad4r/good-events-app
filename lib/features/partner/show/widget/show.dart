import 'package:sukientotapp/core/utils/import/global.dart';

import 'package:sukientotapp/features/components/widget/badge.dart';
import 'package:sukientotapp/features/components/widget/show_detail.dart';

import 'package:sukientotapp/features/common/message/controller.dart';

import 'upload_arrived_photo.dart';
import 'upload_completion_photo.dart';
import 'review.dart';

class Show extends StatelessWidget {
  const Show({
    super.key,
    required this.billId,
    required this.code,
    required this.timestamp,
    required this.price,
    required this.clientName,
    required this.category,
    required this.event,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.note,
    required this.currentStatus,
    this.bookingPhotos = const <String>[],
    this.reviewExists = false,
  });

  final int billId;
  final String code;
  final String timestamp;
  final int price;
  final String clientName;
  final String category;
  final String event;
  final String date;
  final String startTime;
  final String endTime;
  final String address;
  final String note;
  final String currentStatus;
  final List<String> bookingPhotos;
  final bool reviewExists;

  static const Map<String, Map<String, Color>> _statusColors = {
    'pending': {
      'bg': Color(0xFFFFF7ED),
      'text': Color(0xFFC2410C),
      'accent': Color(0xFFF97316),
    },
    'confirmed': {
      'bg': Color(0xFFEFF6FF),
      'text': Color(0xFF1D4ED8),
      'accent': Color(0xFF3B82F6),
    },
    'completed': {
      'bg': Color(0xFFF0FDF4),
      'text': Color(0xFF15803D),
      'accent': Color(0xFF22C55E),
    },
    'expired': {
      'bg': Color(0xFFF9FAFB),
      'text': Color(0xFF6B7280),
      'accent': Color(0xFF9CA3AF),
    },
    'in_job': {
      'bg': Color(0xFFFAF5FF),
      'text': Color(0xFF7E22CE),
      'accent': Color(0xFFA855F7),
    },
    'cancelled': {
      'bg': Color(0xFFFEF2F2),
      'text': Color(0xFFB91C1C),
      'accent': Color(0xFFEF4444),
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors[currentStatus];
    final statusBg = colors?['bg'] ?? const Color(0xFFF3F4F6);
    final statusTextColor = colors?['text'] ?? const Color(0xFF374151);
    final statusAccent = colors?['accent'] ?? const Color(0xFF9CA3AF);

    final String statusLabel = switch (currentStatus) {
      'pending' => 'wait_for_process'.tr,
      'confirmed' => 'confirmed'.tr,
      'completed' => 'completed'.tr,
      'expired' => 'expired'.tr,
      'in_job' => 'in_job'.tr,
      'cancelled' => 'cancelled'.tr,
      _ => currentStatus,
    };

    final bool isActive =
        currentStatus != 'completed' &&
        currentStatus != 'expired' &&
        currentStatus != 'cancelled';
    final bool isActionable =
        currentStatus == 'confirmed' || currentStatus == 'in_job';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.fTheme.colors.muted,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.fTheme.colors.foreground.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent strip
            Container(height: 3, color: statusAccent),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: code + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code,
                              style: context.typography.base.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.fTheme.colors.foreground,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: context.typography.xs.copyWith(
                                  color: statusTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomBadge(
                        text: statusLabel,
                        backgroundColor: statusBg,
                        textColor: statusTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Client name row
                  GestureDetector(
                    onTap: () => logger.d('Tapped on client name: $clientName'),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            FIcons.userRound,
                            size: 14,
                            color: statusTextColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            clientName,
                            style: context.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.fTheme.colors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          FIcons.chevronRight,
                          size: 14,
                          color: context.fTheme.colors.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date & time row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          context,
                          FIcons.calendarDays,
                          date,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        context,
                        FIcons.clock,
                        '$startTime – $endTime',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address
                  _buildInfoChip(context, FIcons.mapPin, address, expand: true),

                  // Price highlight for active statuses
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusAccent.withValues(alpha: 0.14),
                            statusAccent.withValues(alpha: 0.03),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statusAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'your_price'.tr,
                            style: context.typography.xs.copyWith(
                              fontWeight: FontWeight.w500,
                              color: context.fTheme.colors.mutedForeground,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            FormatUtils.formatCurrencyToDoule(price),
                            style: context.typography.base.copyWith(
                              fontWeight: FontWeight.w700,
                              color: statusAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Active footer – tap anywhere to open detail
            if (isActive)
              GestureDetector(
                onTap: () {
                  Get.bottomSheet(
                    ShowDetail(
                      billId: billId,
                      billStatus: currentStatus,
                      code: code,
                      status: statusLabel,
                      statusColor: statusBg,
                      statusTextColor: statusTextColor,
                      clientName: clientName,
                      event: event,
                      startTime: startTime,
                      endTime: endTime,
                      date: date,
                      address: address,
                      note: note,
                      bookingPhotos: bookingPhotos,
                      total: price,
                    ),
                    isScrollControlled: true,
                    backgroundColor: context.fTheme.colors.background,
                    enterBottomSheetDuration: const Duration(milliseconds: 400),
                    exitBottomSheetDuration: const Duration(milliseconds: 300),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: statusBg.withValues(alpha: 0.55),
                    border: Border(
                      top: BorderSide(
                        color: statusAccent.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isActionable) ...[
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (currentStatus == 'in_job') {
                                    Get.bottomSheet(
                                      UploadCompletionPhoto(
                                        code: code,
                                        billId: billId,
                                      ),
                                      isScrollControlled: true,
                                      backgroundColor:
                                          context.fTheme.colors.background,
                                      enterBottomSheetDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      exitBottomSheetDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                    );
                                  } else {
                                    Get.bottomSheet(
                                      UploadArrivedPhoto(
                                        code: code,
                                        billId: billId,
                                      ),
                                      isScrollControlled: true,
                                      backgroundColor:
                                          context.fTheme.colors.background,
                                      enterBottomSheetDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      exitBottomSheetDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: currentStatus == 'in_job'
                                        ? const Color(0xFF15803D)
                                        : statusAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        currentStatus == 'in_job'
                                            ? FIcons.checkCheck
                                            : FIcons.mapPinCheck,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentStatus == 'in_job'
                                            ? 'completed_show'.tr
                                            : 'arrived'.tr,
                                        style: context.typography.xs.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => {
                                Get.isRegistered<MessageController>()
                                    ? Get.find<MessageController>()
                                          .openThreadFromMyShow(billId)
                                    : Get.snackbar('error'.tr, 'error'.tr),
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.fTheme.colors.background
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: context.fTheme.colors.border,
                                  ),
                                ),
                                child: Icon(
                                  FIcons.messageCircleMore,
                                  size: 16,
                                  color: context.fTheme.colors.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            FIcons.clock,
                            size: 11,
                            color: context.fTheme.colors.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timestamp,
                            style: context.typography.xs.copyWith(
                              color: context.fTheme.colors.mutedForeground,
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'detail_info'.tr,
                            style: context.typography.xs.copyWith(
                              color: context.fTheme.colors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            FIcons.arrowRight,
                            color: context.fTheme.colors.primary,
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              // Inactive footer – timestamp + history action
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      FIcons.clock,
                      size: 11,
                      color: context.fTheme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timestamp,
                      style: context.typography.xs.copyWith(
                        color: context.fTheme.colors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (reviewExists)
                      GestureDetector(
                        onTap: () => _openReviewBottomSheet(
                          context,
                          statusAccent: statusAccent,
                          statusBg: statusBg,
                          statusTextColor: statusTextColor,
                        ),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: statusAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: statusAccent.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FIcons.star,
                                size: 13,
                                color: statusTextColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'view_review'.tr,
                                style: context.typography.xs.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: statusTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        FormatUtils.formatCurrencyToDoule(price),
                        style: context.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openReviewBottomSheet(
    BuildContext context, {
    required Color statusAccent,
    required Color statusBg,
    required Color statusTextColor,
  }) {
    Get.bottomSheet(
      ReviewBottomSheet(
        billId: billId,
        code: code,
        clientName: clientName,
        category: category,
        event: event,
        date: date,
        price: price,
        accentColor: statusAccent,
        softColor: statusBg,
        textColor: statusTextColor,
      ),
      isScrollControlled: true,
      backgroundColor: context.fTheme.colors.background,
      enterBottomSheetDuration: const Duration(milliseconds: 350),
      exitBottomSheetDuration: const Duration(milliseconds: 250),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text, {
    bool expand = false,
  }) {
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.fTheme.colors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: expand
          ? Row(
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: context.fTheme.colors.mutedForeground,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.xs.copyWith(
                      color: context.fTheme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: context.fTheme.colors.mutedForeground,
                ),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: context.typography.xs.copyWith(
                    color: context.fTheme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
