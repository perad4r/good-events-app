import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/partner/bottom_navigation/controller.dart';

class BillCountPanel extends StatelessWidget {
  final RxString newShows;
  final RxString waitingConfirmation;

  const BillCountPanel({
    super.key,
    required this.newShows,
    required this.waitingConfirmation,
  });

  @override
  Widget build(BuildContext context) {
    double panelWidth = MediaQuery.of(context).size.width;
    double itemWidth = (panelWidth - 58) / 2;
    final navController = Get.find<PartnerBottomNavigationController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BillItem(
          width: itemWidth,
          iconBgColor: AppColors.primary,
          iconData: FIcons.calendarSearch,
          title: 'take_order',
          count: newShows,
          onTap: () {
            navController.setIndex(1);
          },
        ),
        _BillItem(
          width: itemWidth,
          iconBgColor: AppColors.amber500,
          iconData: FIcons.calendarCheck2,
          title: 'waiting_show',
          count: waitingConfirmation,
          onTap: () {
            navController.setIndex(2, setTab: 0);
          },
        ),
      ],
    );
  }
}

class _BillItem extends StatelessWidget {
  final double width;
  final Color iconBgColor;
  final IconData iconData;
  final String title;
  final RxString count;
  final VoidCallback? onTap;

  const _BillItem({
    required this.width,
    required this.iconBgColor,
    required this.iconData,
    required this.title,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: iconBgColor, size: 22),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.tr,
                    style: context.typography.xs.copyWith(
                      color: context.fTheme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(
                    () => Text(
                      count.value,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
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
