import 'dart:async';

import 'package:sukientotapp/core/services/system_calendar_service.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

bool _hasPromptedThisSession = false;

Future<void> showCalendarPermissionDialogIfNeeded({bool force = false}) async {
  if (_hasPromptedThisSession && !force) return;
  if (!await SystemCalendarService.shouldShowPermissionExplanation()) return;
  _hasPromptedThisSession = true;
  if (!await _waitForNavigator()) {
    _hasPromptedThisSession = false;
    logger.w('[Calendar] Navigator was not ready for permission dialog.');
    return;
  }

  final accepted = await Get.dialog<bool>(
    Builder(
      builder: (context) => Dialog(
        backgroundColor: context.fTheme.colors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FIcons.calendarPlus,
                  size: 28,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm lịch biểu diễn',
                textAlign: TextAlign.center,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.fTheme.colors.foreground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cho phép Sự Kiện Tốt truy cập lịch để tự động thêm các đơn đã xác nhận, cập nhật thời gian và nhắc bạn trước giờ biểu diễn.',
                textAlign: TextAlign.center,
                style: context.typography.sm.copyWith(
                  height: 1.5,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ứng dụng chỉ tạo và cập nhật lịch liên quan đến đơn của bạn.',
                textAlign: TextAlign.center,
                style: context.typography.xs.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Get.back(result: false),
                      child: const Text('Để sau'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: () => Get.back(result: true),
                      child: const Text('Cho phép'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );

  if (accepted == true) {
    await SystemCalendarService.requestPermission();
  }
}

Future<bool> _waitForNavigator() async {
  const attempts = 30;
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (Get.overlayContext != null) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return false;
}
