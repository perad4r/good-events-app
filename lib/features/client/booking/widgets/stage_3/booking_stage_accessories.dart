import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import '../booking_header.dart';

class BookingAccessoriesStage extends GetView<ClientBookingController> {
  const BookingAccessoriesStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingHeader(
          icon: Icons.inventory_2_rounded,
          title: 'booking_stage_accessories_title'.tr,
          subtitle: 'booking_stage_accessories_subtitle'.tr,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFC2410C)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'booking_accessories_fee_notice'.tr,
                  style: context.typography.sm.copyWith(
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isFetchingAccessories.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final accessories = controller.categoryAccessories;
          if (accessories.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'booking_accessories_empty'.tr,
                textAlign: TextAlign.center,
                style: context.typography.sm.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            );
          }
          return Column(
            children: accessories.map((accessory) {
              final selected = controller.selectedAccessoryIds.contains(
                accessory.id,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => controller.toggleAccessory(accessory.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.red600.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.red600
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.red600
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selected
                                  ? AppColors.red600
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            accessory.name,
                            style: context.typography.sm.copyWith(
                              color: context.fTheme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          );
        }),
      ],
    );
  }
}
