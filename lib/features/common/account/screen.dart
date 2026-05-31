import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/home/controller.dart'
    as client_home;
import 'package:sukientotapp/features/partner/home/controller.dart'
    as partner_home;
import 'controller.dart';

import 'widget/wallet_header.dart';

import 'package:sukientotapp/features/components/common/language_switch/language_switch.dart';
import 'package:sukientotapp/features/components/common/notification_button/notification_button.dart';
import 'package:sukientotapp/features/components/widget/confirm_dialog.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountController controller;
  late final RefreshController refreshController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AccountController>();
    refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      resizeToAvoidBottomInset: false,
      header: Obx(
        () => Container(
          padding: EdgeInsets.only(
            top: context.statusBarHeight + 4,
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
                  child: Row(
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
                        child: FAvatar(
                          image: CachedNetworkImageProvider(
                            controller.avatar.value,
                          ),
                          size: 44.0,
                          semanticsLabel: 'User avatar',
                          fallback: const Text('ST'),
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
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
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
                  ),
                ),
              ),
              Row(
                children: [
                  LanguageSwitch(),
                  const SizedBox(width: 10),
                  NotificationButton(
                    hasNotification: controller.role.value == 'partner'
                        ? (Get.isRegistered<
                                partner_home.PartnerHomeController
                              >()
                              ? Get.find<partner_home.PartnerHomeController>()
                                    .hasNotification
                                    .value
                              : false)
                        : (Get.isRegistered<client_home.ClientHomeController>()
                              ? Get.find<client_home.ClientHomeController>()
                                        .summary
                                        .value
                                        ?.isHasNewNoti ??
                                    false
                              : false),
                    onTap: () => Get.toNamed(Routes.notification),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      child: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        enablePullUp: false,
        header: const ClassicHeader(),
        onRefresh: () async {
          await controller.onRefresh();
          if (mounted) {
            refreshController.resetNoData();
            refreshController.refreshCompleted();
          }
        },
        onLoading: () {
          refreshController.loadComplete();
        },
        child: Stack(
          children: [
            Obx(
              () => controller.role.value == 'partner'
                  ? WalletHeader(controller: controller)
                  : const SizedBox.shrink(),
            ),
            Column(
              children: [
                Expanded(
                  child: Container(
                    width: Get.width,
                    margin: EdgeInsets.only(
                      top: controller.role.value == 'partner' ? 100 : 0,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 60),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(context, 'general_setting'.tr),
                            const SizedBox(height: 8),
                            _buildMenuCard(context, [
                              _MenuItem(
                                controller.role.value == 'partner'
                                    ? 'change_to_client'.tr
                                    : 'change_to_partner'.tr,
                                FIcons.userStar,
                                () => ConfirmDialog.show(
                                  title: controller.role.value == 'partner'
                                      ? 'change_to_client'.tr
                                      : 'change_to_partner'.tr,
                                  message: 'change_to_desc'.trParams({
                                    'role': controller.role.value == 'partner'
                                        ? 'customer'.tr
                                        : 'partner'.tr,
                                  }),
                                  confirmText: 'confirm'.tr,
                                  icon: FIcons.userStar,
                                  iconColor: context.primary,
                                  confirmColor: context.primary,
                                  onConfirm: controller.switchRole,
                                ),
                              ),
                              _MenuItem(
                                'my_profile'.tr,
                                FIcons.user,
                                () => Get.toNamed(Routes.myProfile),
                              ),
                              if (controller.role.value == 'partner')
                                _MenuItem(
                                  'show_calendar'.tr,
                                  FIcons.calendar1,
                                  () => Get.toNamed(Routes.partnerShowCalendar),
                                ),
                              if (controller.role.value == 'partner')
                                _MenuItem(
                                  'my_services'.tr,
                                  FIcons.briefcase,
                                  () => Get.toNamed(Routes.partnerMyServices),
                                ),
                              if (controller.role.value == 'partner')
                                _MenuItem(
                                  'revenue_statistics'.tr,
                                  FIcons.chartArea,
                                  () => Get.toNamed(Routes.partnerAnalytics),
                                ),
                              _MenuItem(
                                'change_password'.tr,
                                FIcons.lockKeyholeOpen,
                                () => Get.toNamed(Routes.changePassword),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildSectionLabel(context, 'more_setting'.tr),
                            const SizedBox(height: 8),
                            _buildMenuCard(context, [
                              // _MenuItem(
                              //   'notification_setting'.tr,
                              //   FIcons.bell,
                              //   () {
                              //     AppSnackbar.showInfo(
                              //       title: 'in_dev'.tr,
                              //       message:
                              //           'This feature is under development.',
                              //     );
                              //   },
                              // ),
                              // _MenuItem(
                              //   'message_setting'.tr,
                              //   FIcons.messagesSquare,
                              //   () {
                              //     AppSnackbar.showInfo(
                              //       title: 'in_dev'.tr,
                              //       message:
                              //           'This feature is under development.',
                              //     );
                              //   },
                              // ),
                              _MenuItem(
                                'support'.tr,
                                FIcons.circleQuestionMark,
                                () {},
                              ),
                              _MenuItem(
                                'report_problem'.tr,
                                FIcons.flag,
                                () {},
                              ),
                              _MenuItem(
                                'privacy_policy'.tr,
                                FIcons.shieldCheck,
                                () {
                                  // open webview route
                                  Get.toNamed(
                                    Routes.webView,
                                    arguments: {
                                      'url':
                                          'https://sukientot.com/privacy-policy',
                                      'title': 'privacy_policy'.tr,
                                    },
                                  );
                                },
                              ),
                              _MenuItem(
                                'terms_and_policies'.tr,
                                FIcons.fileText,
                                () {
                                  // open webview route
                                  Get.toNamed(
                                    Routes.webView,
                                    arguments: {
                                      'url':
                                          'https://sukientot.com/chinh-sach-va-quy-dinh',
                                      'title': 'terms_and_policies'.tr,
                                    },
                                  );
                                },
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildMenuCard(context, [
                              _MenuItem(
                                'logout'.tr,
                                FIcons.logOut,
                                () {
                                  ConfirmDialog.show(
                                    title: 'logout_title'.tr,
                                    message: 'logout_message'.tr,
                                    confirmText: 'confirm'.tr,
                                    icon: FIcons.logOut,
                                    iconColor: context.primary,
                                    confirmColor: context.primary,
                                    onConfirm: controller.logout,
                                  );
                                },
                                color: context.fTheme.colors.error,
                              ),
                            ]),
                            const SizedBox(height: 8),
                            _buildMenuCard(context, [
                              _MenuItem(
                                'delete_account'.tr,
                                FIcons.trash2,
                                () => _showDeleteAccountDialog(context),
                                color: context.fTheme.colors.error,
                              ),
                            ]),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Loading overlay
            Obx(
              () => controller.isLoading.value
                  ? Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.fTheme.colors.primary,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    controller.deletePasswordController.clear();
    Get.dialog(
      Dialog(
        backgroundColor: context.fTheme.colors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.fTheme.colors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FIcons.trash2,
                  size: 28,
                  color: context.fTheme.colors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'delete_account_title'.tr,
                textAlign: TextAlign.center,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.fTheme.colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_account_message'.tr,
                textAlign: TextAlign.center,
                style: context.typography.sm.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => TextField(
                  controller: controller.deletePasswordController,
                  obscureText: controller.isDeletePasswordObscure.value,
                  decoration: InputDecoration(
                    labelText: 'password'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isDeletePasswordObscure.value
                            ? FIcons.eyeOff
                            : FIcons.eye,
                        size: 18,
                      ),
                      onPressed: () {
                        controller.isDeletePasswordObscure.value =
                            !controller.isDeletePasswordObscure.value;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.fTheme.colors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('delete_account'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: context.fTheme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (item.color ?? AppColors.primary).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            color: item.color ?? AppColors.primary,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color:
                                item.color ?? context.fTheme.colors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        FIcons.chevronRight,
                        size: 16,
                        color: context.fTheme.colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 16,
                  color: context.fTheme.colors.border.withValues(alpha: 0.5),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem(this.title, this.icon, this.onTap, {this.color});
}
