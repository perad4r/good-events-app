import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';
import 'package:sukientotapp/features/common/report/report_bottom_sheet.dart';

class OrderDetailHeader extends GetView<ClientOrderDetailController> {
  const OrderDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'order_details_title'.tr,
                    style: context.typography.base.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.orderCode,
                    style: context.typography.xl.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                iconColor: const Color(0xFF64748B),
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                onTap: () => controller.onRefresh(),
              ),
              Obx(() {
                if (controller.isHistory.value) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _HeaderIconButton(
                    icon: Icons.flag_rounded,
                    iconColor: AppColors.red600,
                    backgroundColor: Colors.white,
                    borderColor: AppColors.red200,
                    onTap: () {
                      showReportBottomSheet(
                        reportedBillId: controller.orderId,
                        billCode: controller.orderCode,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
