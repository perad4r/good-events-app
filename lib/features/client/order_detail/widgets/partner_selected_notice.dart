import 'package:sukientotapp/core/utils/import/global.dart';

class PartnerSelectedNotice extends StatelessWidget {
  const PartnerSelectedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle contentStyle = context.typography.sm.copyWith(
      color: context.fTheme.colors.foreground,
      height: 1.45,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 14,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            Positioned(
              top: 34,
              right: 16,
              child: Icon(
                Icons.star_rounded,
                size: 13,
                color: const Color(0xFFF4B740).withValues(alpha: 0.72),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              child: Icon(
                Icons.circle,
                size: 6,
                color: const Color(0xFFF4B740).withValues(alpha: 0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'partner_selected_notice_title'.tr,
                    textAlign: TextAlign.center,
                    style: context.typography.lg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'partner_selected_notice_subtitle'.tr,
                    textAlign: TextAlign.center,
                    style: context.typography.sm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.forum_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: context.typography.xs.copyWith(
                        color: context.fTheme.colors.mutedForeground,
                        height: 1.4,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
