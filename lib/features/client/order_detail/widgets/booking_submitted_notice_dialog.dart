import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class BookingSubmittedNoticeDialog extends StatelessWidget {
  const BookingSubmittedNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'booking_submitted_notice_title'.tr,
              textAlign: TextAlign.center,
              style: context.typography.lg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'booking_submitted_notice_content'.tr,
              textAlign: TextAlign.center,
              style: context.typography.sm.copyWith(
                color: context.fTheme.colors.mutedForeground,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'booking_submitted_notice_subtitle'.tr,
              textAlign: TextAlign.center,
              style: context.typography.xs.copyWith(
                color: context.fTheme.colors.mutedForeground,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            CustomButtonPlus(
              onTap: () => Get.back(),
              btnText: 'booking_submitted_notice_button'.tr,
              height: 46,
              borderRadius: 12,
              fontWeight: FontWeight.w700,
              textSize: 14,
              color: AppColors.primary,
              borderColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
