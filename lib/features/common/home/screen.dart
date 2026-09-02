import 'package:sukientotapp/features/common/home/controller.dart';
import 'package:sukientotapp/features/common/home/widget/category_intro_card.dart';
import 'package:sukientotapp/features/common/home/widget/user_switch.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

import 'package:sukientotapp/features/components/button/plus.dart';

import 'package:sukientotapp/features/common/home/widget/guest_intro_card.dart';
import 'package:sukientotapp/features/client/home/widgets/blogs_panel.dart';
import 'package:sukientotapp/features/client/home/widgets/fake_search_bar.dart';
import 'package:sukientotapp/features/components/common/language_switch/language_switch.dart';

class GuestHomeScreen extends GetView<GuestHomeController> {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).viewPadding.top;
    return FScaffold(
      header: Obx(
        () => Container(
          padding: EdgeInsets.only(top: statusBarHeight, left: 16, right: 16, bottom: 5),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.lightBackground,
                AppColors.red50,
              ],
            ),
          ),
          child: Column(
            children: [
              //first row: title and user switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home'.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.userType.value ? 'customer'.tr : 'partner'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      UserRoleSwitch(
                        rxValue: controller.userType,
                        activeBackgroundColor: Colors.yellow[900]!,
                        inactiveBackgroundColor: Colors.red[900]!,
                        activeImageWidget: Icon(
                          Icons.person_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 22,
                        ),
                        inactiveImageWidget: Icon(
                          Icons.business_center_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 5),
                      LanguageSwitch(),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              //second row: CTA register
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  border: Border.all(color: AppColors.red200),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red200.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //CTA register text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'dont_have_account'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.userType.value
                                ? 'customer_register_now'.tr
                                : 'partner_register_now'.tr,
                            softWrap: true,
                            maxLines: 2,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(AppImages.placeHolder, width: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      footer: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomButtonPlus(
                  btnText: 'register'.tr,
                  onTap: () => Get.toNamed(Routes.registerScreen),
                  width: Get.width * 0.4,
                  color: Colors.white,
                  textColor: controller.userType.value ? AppColors.amber600 : AppColors.primary,
                  borderColor: controller.userType.value ? AppColors.amber600 : AppColors.primary,
                ),
                CustomButtonPlus(
                  btnText: 'login'.tr,
                  onTap: () => Get.toNamed(Routes.loginScreen),
                  width: Get.width * 0.4,
                  color: controller.userType.value ? AppColors.amber600 : AppColors.primary,
                  borderColor: controller.userType.value ? AppColors.amber600 : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Obx(
              () => controller.userType.value
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(5, 12, 5, 0),
                      child: FakeSearchBar(
                        onTap: () {
                          controller.ensurePartnersLoaded();
                          controller.openCategoryListScreen();
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: GuestIntroCard(),
            ),
            Obx(
              () => controller.userType.value
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CategoryIntroCard(),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'news_and_blogs'.tr,
                    style: context.typography.lg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isLoadingBlogs.value && controller.blogs.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.blogs.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'no_blogs'.tr,
                      style: context.typography.sm.copyWith(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ClientBlogPanel(blogs: controller.blogs);
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
