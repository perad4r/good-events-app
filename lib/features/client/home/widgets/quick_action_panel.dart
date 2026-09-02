import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/home/controller.dart';

class ClientQuickActionPanel extends StatelessWidget {
  const ClientQuickActionPanel({super.key, required this.controller});

  final ClientHomeController controller;

  @override
  Widget build(BuildContext context) {
    return _QuickActionPanel(
      items: [
        _QuickActionItem(
          icon: FIcons.accessibility,
          label: 'partner'.tr,
          animationDelayMs: 200,
          onPress: () {
            controller.ensurePartnersLoaded();
            controller.openCategoryListScreen();
          },
          color: const Color(0xFF3B82F6),
        ),
        _QuickActionItem(
          icon: FIcons.speaker,
          label: 'rent_product'.tr,
          animationDelayMs: 220,
          onPress: () {
            Get.toNamed(
              Routes.webView,
              arguments: {
                'url': 'https://sukientot.com/thue-vat-tu',
                'title': 'rent_product'.tr,
                'allowReload': true,
              },
            );
          },
          color: const Color(0xFF10B981),
        ),
        _QuickActionItem(
          icon: FIcons.bookImage,
          label: 'file_product'.tr,
          animationDelayMs: 240,
          onPress: () {
            Get.toNamed(
              Routes.webView,
              arguments: {
                'url': 'https://sukientot.com/tai-lieu',
                'title': 'file_product'.tr,
                'allowReload': true,
              },
            );
          },
          color: const Color(0xFFF59E0B),
        ),
        _QuickActionItem(
          icon: FIcons.bookOpenText,
          label: 'news_and_blogs'.tr,
          animationDelayMs: 260,
          onPress: () {
            Get.toNamed(
              Routes.webView,
              arguments: {
                'url': 'https://sukientot.com/dia-diem-to-chuc-su-kien',
                'title': 'news_and_blogs'.tr,
                'allowReload': true,
              },
            );
          },
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

class _QuickActionPanel extends StatelessWidget {
  const _QuickActionPanel({required this.items});

  final List<_QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.zap, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'quick_actions'.tr,
                style: context.typography.sm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.fTheme.colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map(
                  (item) => _buildButtonItem(
                    context,
                    item.icon,
                    item.label,
                    item.onPress,
                    item.color,
                    item.animationDelayMs,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPress,
    Color color,
    int animationDelayMs,
  ) {
    return GestureDetector(
      onTap: onPress,
      child: SizedBox(
        width: 62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label.tr,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: context.typography.xs.copyWith(
                color: context.fTheme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate(delay: animationDelayMs.ms).fadeIn(duration: 200.ms),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onPress;
  final int animationDelayMs;
  final Color color;

  _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onPress,
    required this.animationDelayMs,
    required this.color,
  });
}
