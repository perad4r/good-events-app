import 'package:fl_chart/fl_chart.dart';

import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/partner/home/controller.dart';

import 'package:sukientotapp/features/components/common/language_switch/language_switch.dart';
import 'package:sukientotapp/features/components/common/notification_button/notification_button.dart';
import 'package:sukientotapp/features/components/common/partner_chart/income_chart.dart';

import 'widgets/qick_actions_panel.dart';
import 'widgets/income_panel.dart';
import 'widgets/bill_count_panel.dart';
// import 'widgets/new_review_panel.dart';

class HomeScreen extends GetView<PartnerHomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return FScaffold(
      header: Container(
        padding: EdgeInsets.only(
          top: statusBarHeight + 4,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.78),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.myProfile),
                child:
                    Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                              child: Obx(
                                () => FAvatar(
                                  image: CachedNetworkImageProvider(
                                    controller.avatar.value,
                                  ),
                                  size: 44.0,
                                  semanticsLabel: 'User avatar',
                                  fallback: const Text('ST'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.name.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          FIcons.badgeCheck,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          controller.isLegit.value == 'true'
                                              ? 'verified'.tr
                                              : 'unverified'.tr,
                                          style: context.typography.xs.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),
              ),
            ),
            Row(
              children: [
                LanguageSwitch(),
                const SizedBox(width: 10),
                Obx(
                  () => NotificationButton(
                    hasNotification: controller.hasNotification.value,
                    onTap: () => Get.toNamed(Routes.notification),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
          ],
        ),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.dashboardData.value;
        if (data == null) {
          return Center(child: Text('no_data'.tr));
        }

        final revenueData = data.quarterlyRevenue;
        final revenueSpots = revenueData.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.toDouble());
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 80),
          child: Column(
            children: [
              IncomePanel(
                balance: controller.balance.value,
                revenue: data.revenue,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 14),
              QickActionsPanel()
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 14),
              BillCountPanel(
                    newShows: controller.newBillCount,
                    waitingConfirmation: controller.waitingBillCount,
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 14),
              // NewReviewPanel(
              //       recentReviewsCount: data.recentReviewsCount,
              //       recentReviewsAvatars: data.recentReviewsAvatars,
              //     )
              //     .animate(delay: 300.ms)
              //     .fadeIn(duration: 400.ms)
              //     .slideY(begin: 0.1, end: 0),
              // const SizedBox(height: 14),
              IncomeChart(
                    spots: revenueSpots.isNotEmpty
                        ? revenueSpots
                        : [
                            FlSpot(0, 0),
                            FlSpot(1, 0),
                            FlSpot(2, 0),
                            FlSpot(3, 0),
                          ],
                    unit: '₫',
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        );
      }),
    );
  }
}
