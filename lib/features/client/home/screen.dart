import 'package:sukientotapp/core/utils/import/global.dart';

import 'package:sukientotapp/features/client/home/widgets/bill_count.dart';
import 'package:sukientotapp/features/client/home/widgets/blogs_panel.dart';
import 'package:sukientotapp/features/client/home/widgets/header.dart';
import 'package:sukientotapp/features/client/home/widgets/new_order.dart';
import 'package:sukientotapp/features/client/home/widgets/quick_action_panel.dart';
import 'package:sukientotapp/features/client/home/widgets/fake_search_bar.dart';
import 'package:sukientotapp/features/client/home/widgets/category_intro_card.dart';

// import 'package:url_launcher/url_launcher.dart';

import 'controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ClientHomeController controller;
  late final RefreshController refreshController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClientHomeController>();
    refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientHomeHeader(controller: controller),
            const SizedBox(height: 14),
            FakeSearchBar(
              onTap: () {
                controller.ensurePartnersLoaded();
                controller.openCategoryListScreen();
              },
            ),
          ],
        ),
      ),

      child: SmartRefresher(
        controller: refreshController,
        onRefresh: () async {
          await controller.onRefresh();
          if (mounted) {
            refreshController.resetNoData();
            refreshController.refreshCompleted();
          }
        },
        enablePullUp: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientQuickActionPanel(controller: controller)
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 14),
            ClientBillCountPanel(controller: controller)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 14),
            NewOrderPanel(controller: controller)
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CategoryIntroCard(),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'news_and_blogs'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(
                      Routes.webView,
                      arguments: {
                        'url': 'https://sukientot.com/dia-diem-to-chuc-su-kien',
                        'title': 'news_and_blogs'.tr,
                      },
                    );
                  },
                  child: Text(
                    'see_more'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ).animate(delay: 400.ms).fadeIn(duration: 200.ms),

            const SizedBox(height: 14),
            ClientBlogPanel(blogs: controller.blogs),

            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }
}
