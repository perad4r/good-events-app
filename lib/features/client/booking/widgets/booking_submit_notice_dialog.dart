import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class BookingSubmitNoticeDialog extends StatelessWidget {
  const BookingSubmitNoticeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 18,
            left: 18,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 70,
            right: 22,
            child: Icon(
              Icons.star_rounded,
              size: 14,
              color: const Color(0xFFF4B740).withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            bottom: 82,
            left: 13,
            child: Icon(
              Icons.circle,
              size: 7,
              color: const Color(0xFFF4B740).withValues(alpha: 0.5),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FTappable(
                        onPress: () => Get.back(result: false),
                        child: Icon(
                          FIcons.x,
                          size: 20,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'booking_submit_notice_title_prefix'.tr,
                            ),
                            TextSpan(
                              text: 'booking_submit_notice_title_primary'.tr,
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: context.typography.lg.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NoticeItem(
                      icon: Icons.groups_rounded,
                      title: 'booking_submit_notice_platform_title'.tr,
                      content: 'booking_submit_notice_platform_content'.tr,
                    ),
                    _NoticeItem(
                      icon: Icons.fact_check_outlined,
                      title: 'booking_submit_notice_confirm_title'.tr,
                      content: 'booking_submit_notice_confirm_content'.tr,
                    ),
                    _NoticeItem(
                      icon: Icons.handshake_outlined,
                      title: 'booking_submit_notice_agreement_title'.tr,
                      content: 'booking_submit_notice_agreement_content'.tr,
                    ),
                    _NoticeItem(
                      icon: Icons.support_agent_rounded,
                      title: 'booking_submit_notice_support_title'.tr,
                      content: 'booking_submit_notice_support_content'.tr,
                      bottomSpacing: 12,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'booking_submit_notice_note'.tr,
                              style: context.typography.sm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'booking_submit_notice_closing'.tr,
                        textAlign: TextAlign.center,
                        style: context.typography.sm.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                  child: CustomButtonPlus(
                onTap: () => Get.back(result: true),
                btnText: 'booking_submit_notice_confirm_button'.tr,
                icon: Icons.search_rounded,
                iconSize: 18,
                height: 48,
                borderRadius: 12,
                fontWeight: FontWeight.w800,
                textSize: 14,
                color: AppColors.primary,
                borderColor: Colors.transparent,
                shrinkText: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  const _NoticeItem({
    required this.icon,
    required this.title,
    required this.content,
    this.bottomSpacing = 12,
  });

  final IconData icon;
  final String title;
  final String content;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.sm.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: context.typography.xs.copyWith(
                    color: context.fTheme.colors.mutedForeground,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
