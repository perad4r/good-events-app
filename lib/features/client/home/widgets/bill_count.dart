import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/client/home/controller.dart';
import 'package:sukientotapp/features/client/order/controller.dart';

class ClientBillCountPanel extends StatelessWidget {
  const ClientBillCountPanel({super.key, required this.controller});

  final ClientHomeController controller;

  @override
  Widget build(BuildContext context) {
    double panelWidth = MediaQuery.of(context).size.width;
    double itemWidth = (panelWidth - 36) / 2;
    return Obx(() {
      final summary = controller.summary.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BillItem(
            width: itemWidth,
            iconBgColor: AppColors.primary,
            iconData: FIcons.calendarSearch,
            title: 'pending_order',
            count: summary?.pendingOrders.toString() ?? "0",
            type: 'pending',
          ),
          _BillItem(
            width: itemWidth,
            iconBgColor: AppColors.amber500,
            iconData: FIcons.calendarCheck2,
            title: 'confirmed_order',
            count: summary?.confirmedOrders.toString() ?? "0",
            type: 'confirmed',
          ),
        ],
      ).animate(delay: 300.ms).fadeIn(duration: 200.ms);
    });
  }
}

class _BillItem extends StatefulWidget {
  final double width;
  final Color iconBgColor;
  final IconData iconData;
  final String title;
  final String count;
  final String type;

  const _BillItem({
    required this.width,
    required this.iconBgColor,
    required this.iconData,
    required this.title,
    required this.count,
    required this.type,
  });

  @override
  State<_BillItem> createState() => _BillItemState();
}

class _BillItemState extends State<_BillItem> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller?.forward().then((_) => _controller?.reverse());

        Get.find<ClientOrderController>().selectedStatusFilters.value = [widget.type];
        Get.find<ClientBottomNavigationController>().setIndex(1);
      },
      child:
          Container(
                width: widget.width,
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
                        color: widget.iconBgColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.iconData,
                        color: widget.iconBgColor,
                        size: 22,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.tr,
                            style: context.typography.xs.copyWith(
                              color: context.fTheme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.count,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(
                autoPlay: false,
                onInit: (controller) => _controller = controller,
              )
              .scaleXY(end: 0.95, duration: 100.ms, curve: Curves.easeInOut),
    );
  }
}
