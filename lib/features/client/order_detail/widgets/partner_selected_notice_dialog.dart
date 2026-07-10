import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class PartnerSelectedNoticeDialog extends StatelessWidget {
  const PartnerSelectedNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle contentStyle = context.typography.sm.copyWith(
      color: context.fTheme.colors.foreground,
      height: 1.5,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
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
                left: 18,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                top: 52,
                right: 22,
                child: Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: const Color(0xFFF4B740).withValues(alpha: 0.75),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 14,
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: const Color(0xFFF4B740).withValues(alpha: 0.55),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        Icons.celebration_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'partner_selected_notice_title'.tr,
                      textAlign: TextAlign.center,
                      style: context.typography.xl.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'partner_selected_notice_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: context.typography.xl.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: contentStyle,
                                children: [
                                  TextSpan(
                                    text: 'partner_selected_notice_content'.tr,
                                  ),
                                  TextSpan(
                                    text:
                                        'partner_selected_notice_content_emphasis'
                                            .tr,
                                    style: contentStyle.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: context.typography.sm.copyWith(
                          color: context.fTheme.colors.mutedForeground,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(text: 'partner_selected_notice_wish'.tr),
                          TextSpan(
                            text: 'partner_selected_notice_wish_emphasis'.tr,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButtonPlus(
                      onTap: () => Get.back(),
                      btnText: 'partner_selected_notice_button'.tr,
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
