import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/client/home_repository.dart';

import 'package:sukientotapp/data/models/client/home_summary_model.dart';
import 'package:sukientotapp/data/models/client/blog_home_model.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';

import 'package:sukientotapp/features/client/home/widgets/popup_search_sheet.dart';
import 'package:sukientotapp/features/client/home/widgets/app_notification_card.dart';

class ClientHomeController extends GetxController {
  final HomeRepository _repository;
  ClientHomeController(this._repository);

  // States
  final Rx<HomeSummaryModel?> summary = Rx<HomeSummaryModel?>(null);
  final RxList<BlogItemModel> blogs = <BlogItemModel>[].obs;
  final RxList<PartnerCategoryModel> partnerList = <PartnerCategoryModel>[].obs;

  // Loaders
  final isLoadingSummary = false.obs;
  final isLoadingBlogs = false.obs;
  final isLoadingPartners = false.obs;
  final isAppNotificationDismissed = true.obs;

  Future<void> onRefresh() async {
    await fetchSummary();
  }

  // User data
  RxString name =
      (StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'name') ??
              '')
          .toString()
          .obs;

  RxString avatar =
      (StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'avatar_url',
              ) ??
              '')
          .toString()
          .obs;

  @override
  void onInit() {
    super.onInit();
    syncFromStorage();
    // Load all data on mount
    fetchSummary(showAppNotification: true);
    fetchBlogs();
    fetchPartners();

    logger.i('Fetched home summary: ${summary.value?.notification?.type}');
  }

  void syncFromStorage() {
    name.value =
        (StorageService.readMapData(
                  key: LocalStorageKeys.user,
                  mapKey: 'name',
                ) ??
                '')
            .toString();
    avatar.value =
        (StorageService.readMapData(
                  key: LocalStorageKeys.user,
                  mapKey: 'avatar_url',
                ) ??
                '')
            .toString();
  }

  Future<void> fetchSummary({bool showAppNotification = false}) async {
    if (isLoadingSummary.value) return;
    HomeSummaryModel? homeSummary;
    isLoadingSummary.value = true;
    try {
      homeSummary = await _repository.getHomeSummary();
      summary.value = homeSummary;
      isAppNotificationDismissed.value =
          homeSummary.notification == null ||
          !homeSummary.notification!.canDisplay;
    } catch (e) {
      logger.e('Failed to fetch home summary: $e');
    } finally {
      isLoadingSummary.value = false;
    }

    if (showAppNotification && homeSummary != null) {
      await _showStartupDialogs(homeSummary.notification);
    }
  }

  void dismissAppNotification() {
    isAppNotificationDismissed.value = true;
  }

  Future<void> _showStartupDialogs(AppNotification? appNotification) async {
    await Future<void>.delayed(Duration.zero);

    if (appNotification != null &&
        appNotification.canDisplay &&
        !isAppNotificationDismissed.value) {
      await _showAppNotificationDialog(appNotification);
    }
  }

  Future<void> _showAppNotificationDialog(AppNotification notification) async {
    await Get.dialog<void>(
      ClientAppNotificationCard(
        notification: notification,
        onDismiss: () {
          dismissAppNotification();
          Get.back<void>();
        },
      ),
      barrierDismissible: true,
    );

    dismissAppNotification();
  }

  HomeSummaryModel _currentSummaryOrDefault() {
    return summary.value ??
        const HomeSummaryModel(
          isHasNewNoti: false,
          notification: null,
          pendingOrders: 0,
          confirmedOrders: 0,
          pendingPartners: 0,
          pendingPartnerAvatars: <String>[],
        );
  }

  void _updateSummary(
    HomeSummaryModel Function(HomeSummaryModel current) updater,
  ) {
    summary.value = updater(_currentSummaryOrDefault());
  }

  void setHasNewNotification(bool value) {
    _updateSummary((current) {
      return current.copyWith(isHasNewNoti: value);
    });
  }

  void incrementPendingOrders({int by = 1}) {
    if (by <= 0) return;

    _updateSummary((current) {
      return current.copyWith(pendingOrders: current.pendingOrders + by);
    });
  }

  void confirmOrder({int applicantCount = 0}) {
    final int safeApplicantCount = applicantCount < 0 ? 0 : applicantCount;

    _updateSummary((current) {
      final int nextPendingOrders = current.pendingOrders > 0
          ? current.pendingOrders - 1
          : 0;
      final int nextConfirmedOrders = current.confirmedOrders + 1;
      final int nextPendingPartners =
          current.pendingPartners > safeApplicantCount
          ? current.pendingPartners - safeApplicantCount
          : 0;

      final List<String> nextAvatars;
      if (safeApplicantCount <= 0 || current.pendingPartnerAvatars.isEmpty) {
        nextAvatars = current.pendingPartnerAvatars;
      } else if (safeApplicantCount >= current.pendingPartnerAvatars.length) {
        nextAvatars = <String>[];
      } else {
        nextAvatars = current.pendingPartnerAvatars.sublist(
          0,
          current.pendingPartnerAvatars.length - safeApplicantCount,
        );
      }

      return current.copyWith(
        pendingOrders: nextPendingOrders,
        confirmedOrders: nextConfirmedOrders,
        pendingPartners: nextPendingPartners,
        pendingPartnerAvatars: nextAvatars,
      );
    });
  }

  Future<void> fetchBlogs() async {
    if (isLoadingBlogs.value) return;
    isLoadingBlogs.value = true;
    try {
      final res = await _repository.getHomeBlogs();
      blogs.assignAll(res);
    } catch (e) {
      logger.e('Failed to fetch home blogs: $e');
    } finally {
      isLoadingBlogs.value = false;
    }
  }

  Future<void> fetchPartners({bool force = false}) async {
    if (isLoadingPartners.value) return;
    if (!force && partnerList.isNotEmpty) return;

    isLoadingPartners.value = true;
    try {
      final res = await _repository.getPartnerCategories();
      partnerList.assignAll(res);
    } catch (e) {
      logger.e('Failed to fetch partner categories: $e');
    } finally {
      isLoadingPartners.value = false;
    }
  }

  void ensurePartnersLoaded() {
    if (partnerList.isEmpty && !isLoadingPartners.value) {
      fetchPartners();
    }
  }

  void openBrowser(String url) async {
    /// will implement later (url_launcher lib)
    // if (await canLaunchUrl(Uri.parse(url))) {
    //   await launchUrl(Uri.parse(url));
    // } else {
    //   throw 'Could not launch $url';
    // }
  }

  void openDetailScreen(String slug) async {
    var result = await Get.toNamed(
      Routes.partnerDetail,
      arguments: {'slug': slug},
    );

    if (result == "show_category_bottom_sheet") {
      Future.delayed(const Duration(milliseconds: 400), () {
        openCategoryListBottomSheet(Get.context!);
      });
    }
  }

  void openCategoryListBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PopupPartnerSearchSheet(
        partnerCategories: partnerList,
        isLoadingPartners: isLoadingPartners,
      ),
      isScrollControlled: true,
    );
  }
}
