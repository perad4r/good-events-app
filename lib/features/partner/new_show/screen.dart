import 'package:flutter/cupertino.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'controller.dart';

import './widgets/show.dart';

import 'package:sukientotapp/features/components/button/circle.dart';
import 'package:sukientotapp/features/partner/show/widget/filter_sheet.dart';

class NewShowScreen extends GetView<NewShowController> {
  const NewShowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: Padding(
        padding: EdgeInsets.only(
          top: context.statusBarHeight,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'new_show'.tr,
                  textAlign: TextAlign.left,
                  style: context.typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.fTheme.colors.foreground,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => CircleButton(
                    icon: FIcons.listFilter,
                    iconColor: controller.isFilterActive
                        ? context.fTheme.colors.primaryForeground
                        : context.fTheme.colors.primary,
                    onPressed: () => Get.bottomSheet(
                      FilterSheetWidget(
                        initialSearch: controller.filterSearch.value,
                        initialDate: controller.filterDate.value,
                        initialSort: controller.filterSort.value,
                        onApply:
                            ({
                              required search,
                              required dateFilter,
                              required sort,
                            }) => controller.applyFilter(
                              search: search,
                              dateFilter: dateFilter,
                              sort: sort,
                            ),
                        onClear: controller.clearFilter,
                      ),
                      isScrollControlled: true,
                      enterBottomSheetDuration: const Duration(
                        milliseconds: 300,
                      ),
                      exitBottomSheetDuration: const Duration(
                        milliseconds: 250,
                      ),
                    ),
                    size: 34,
                    backgroundColor: controller.isFilterActive
                        ? context.fTheme.colors.primary
                        : context.fTheme.colors.muted,
                  ),
                ),
              ],
            ),

            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'last_update'.trParams({
                      'time': controller.lastUpdated.value.isEmpty
                          ? '...'
                          : controller.lastUpdated.value,
                    }),
                    style: context.typography.sm.copyWith(
                      color: context.fTheme.colors.mutedForeground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.refreshBills(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red600.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.red600.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FIcons.refreshCw,
                            size: 13,
                            color: AppColors.red600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'refresh'.tr,
                            style: context.typography.xs.copyWith(
                              color: AppColors.red600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.bills.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final bills = controller.isFilterActive
            ? controller.filteredBills
            : controller.bills;

        if (bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  controller.isFilterActive
                      ? CupertinoIcons.search
                      : CupertinoIcons.tray,
                  size: 56,
                  color: context.fTheme.colors.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.isFilterActive
                      ? 'no_filter_results'.tr
                      : 'no_bills'.tr,
                  style: context.typography.sm.copyWith(
                    color: context.fTheme.colors.mutedForeground,
                  ),
                ),
                if (controller.isFilterActive) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: controller.clearFilter,
                    child: Text(
                      'clear_filter'.tr,
                      style: context.typography.xs.copyWith(
                        color: context.fTheme.colors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          itemCount:
              bills.length +
              (!controller.isFilterActive && controller.isLoading.value
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            if (index == bills.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final bill = bills[index];
            return Show(
              billId: bill.id,
              code: bill.code,
              timestamp: bill.createdAt,
              price: bill.finalTotal != null
                  ? '${bill.finalTotal!.toStringAsFixed(0)} VND'
                  : 'Chưa có',
              clientName: bill.clientName,
              category: bill.categoryName,
              categoryImage: bill.categoryImage,
              event: bill.eventName,
              date: bill.date,
              startTime: bill.startTime,
              endTime: bill.endTime,
              address: bill.address,
              note: bill.note ?? 'unknown',
              bookingPhotos: bill.bookingPhotos,
            );
          },
        );
      }),
    );
  }
}
