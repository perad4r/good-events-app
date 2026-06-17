import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

import './show.dart';
import './filter_sheet.dart';

import 'package:sukientotapp/features/partner/show/controller.dart';

class HistoryWidget extends GetView<ShowController> {
  const HistoryWidget({super.key});

  Widget _buildToolbarBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.12)
              : context.fTheme.colors.muted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                color?.withValues(alpha: 0.35) ?? context.fTheme.colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? context.fTheme.colors.foreground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() {
            if (controller.isHistoryLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final bills = controller.isFilterActive
                ? controller.filteredHistoryBills
                : controller.historyBills;
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
                    if (controller.isFilterActive) ...
                      [
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => controller.clearFilter(),
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
            final showLoadMore = !controller.isFilterActive &&
                controller.isHistoryLoadMore.value;
            return ListView.builder(
              controller: controller.historyScrollController,
              padding: const EdgeInsets.only(top: 60, bottom: 100),
              itemCount: bills.length + (showLoadMore ? 1 : 0),
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
                      timestamp: bill.updatedAt,
                      price: bill.finalTotal,
                      clientName: bill.clientName,
                      category: bill.category,
                      event: bill.event,
                      date: bill.date,
                      startTime: bill.startTime,
                      endTime: bill.endTime,
                      address: bill.address,
                      note: bill.note ?? '',
                      currentStatus: bill.status,
                      reviewExists: bill.isReviewed == true,
                    )
                    .animate(delay: (100 * index).ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.02, end: 0, curve: Curves.easeOut);
              },
            );
          }),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.fTheme.colors.background.withAlpha(210),
                  border: Border(
                    bottom: BorderSide(
                      color: context.fTheme.colors.border.withAlpha(80),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.fTheme.colors.muted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.fTheme.colors.border,
                          ),
                        ),
                        child: Text(
                          controller.isFilterActive
                              ? '${controller.filteredHistoryBills.length}'
                              : '${controller.historyBills.length}',
                          style: context.typography.xs.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.fTheme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Obx(() {
                      if (!controller.isFilterActive) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => controller.clearFilter(),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.red600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.red600.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'clear_filter'.tr,
                            style: context.typography.xs.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.red600,
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    _buildToolbarBtn(
                      context,
                      icon: FIcons.refreshCw,
                      onTap: () => controller.refreshData(),
                      color: AppColors.red600,
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => _buildToolbarBtn(
                        context,
                        icon: FIcons.listFilterPlus,
                        onTap: () => Get.bottomSheet(
                          FilterSheetWidget(
                            initialSearch: controller.filterSearch.value,
                            initialDate: controller.filterDate.value,
                            initialSort: controller.filterSort.value,
                            onApply: (
                              {required search,
                              required dateFilter,
                              required sort}) => controller.applyFilter(
                              search: search,
                              dateFilter: dateFilter,
                              sort: sort,
                            ),
                            onClear: controller.clearFilter,
                          ),
                          isScrollControlled: true,
                          enterBottomSheetDuration:
                              const Duration(milliseconds: 300),
                          exitBottomSheetDuration:
                              const Duration(milliseconds: 250),
                        ),
                        color: controller.isFilterActive
                            ? context.fTheme.colors.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
