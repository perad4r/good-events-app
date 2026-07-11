import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class BookingSubmittedNoticeDialog extends StatelessWidget {
  const BookingSubmittedNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                top: 18,
                left: 20,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: AppColors.primary.withValues(alpha: 0.32),
                ),
              ),
              Positioned(
                top: 50,
                right: 24,
                child: Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: const Color(0xFFF4B740).withValues(alpha: 0.72),
                ),
              ),
              Positioned(
                bottom: 78,
                left: 15,
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: const Color(0xFFF4B740).withValues(alpha: 0.52),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.primary,
                        size: 29,
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
                      icon: Icons.check_circle_outline_rounded,
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
            ],
          ),
        ),
      ),
    );
  }
}
