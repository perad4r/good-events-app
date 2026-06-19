import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/partner/dashboard_repository.dart';
import 'package:sukientotapp/data/models/partner/dashboard_model.dart';

class PartnerHomeController extends GetxController {
  final DashboardRepository _dashboardRepository;

  PartnerHomeController(this._dashboardRepository);

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
  RxString isLegit =
      (StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'is_legit',
              ) ??
              false)
          .toString()
          .obs;

  RxInt balance = RxInt(
    (StorageService.readMapData(
              key: LocalStorageKeys.user,
              mapKey: 'wallet_balance',
            )
            as int?) ??
        0,
  );

  RxString newBillCount = "0".obs;
  RxString waitingBillCount = "0".obs;

  RxBool hasNotification = false.obs;

  RxBool isLoading = true.obs;
  Rxn<DashboardModel> dashboardData = Rxn<DashboardModel>();

  @override
  void onInit() async {
    super.onInit();
    await fetchDashboardData();

    newBillCount = RxString(
      (StorageService.readData(key: LocalStorageKeys.newBill) ?? '0'),
    );
    waitingBillCount = RxString(
      (StorageService.readData(key: LocalStorageKeys.waitingBill) ?? '0'),
    );
    hasNotification = RxBool(
      (StorageService.readData(key: LocalStorageKeys.hasNotification) ?? false)
          as bool,
    );

    //check if balance is change from backend
    final currentBalance = balance.value;
    final newBalance = dashboardData.value?.balance;
    if (newBalance != null && newBalance != currentBalance) {
      balance.value = newBalance;

      StorageService.writeSingleMapData(
        key: LocalStorageKeys.user,
        mapKey: 'wallet_balance',
        value: newBalance,
      );
    }
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

  void syncBalance() {
    balance.value =
        (StorageService.readMapData(
                  key: LocalStorageKeys.user,
                  mapKey: 'wallet_balance',
                ) ??
                0)
            .toInt();
  }

  void updateShowDataOnNewBill({int count = 1}) {
    final currentNew = int.tryParse(newBillCount.value) ?? 0;
    newBillCount.value = (currentNew + count).toString();
  }

  void updateShowDataOnConfirmedByClient({int count = 1}) {
    final currentWaiting = int.tryParse(waitingBillCount.value) ?? 0;
    waitingBillCount.value = (currentWaiting - count)
        .clamp(0, double.maxFinite.toInt())
        .toString();
  }

  void updateShowDataOnCancelAccept() {
    final currentWaiting = int.tryParse(waitingBillCount.value) ?? 0;

    waitingBillCount.value = (currentWaiting - 1)
        .clamp(0, double.maxFinite.toInt())
        .toString();
  }

  void updateShowDataOnAccept() {
    final currentNew = int.tryParse(newBillCount.value) ?? 0;
    newBillCount.value = (currentNew - 1)
        .clamp(0, double.maxFinite.toInt())
        .toString();

    final currentWaiting = int.tryParse(waitingBillCount.value) ?? 0;
    waitingBillCount.value = (currentWaiting + 1).toString();
  }

  void setHasNotification(bool value) {
    final current = dashboardData.value;
    if (current == null) return;

    dashboardData.value = DashboardModel(
      balance: current.balance,
      revenue: current.revenue,
      recentReviewsCount: current.recentReviewsCount,
      recentReviewsAvatars: current.recentReviewsAvatars,
      quarterlyRevenue: current.quarterlyRevenue,
    );
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final data = await _dashboardRepository.getDashboardData();
      dashboardData.value = data;
      if (isLegit.value == 'false') {
        _showVerifyBanner();
      }
    } catch (e) {
      logger.e('[PartnerHomeController] [fetchDashboardData] error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showVerifyBanner() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.amber500,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'verify_account_cta'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'verify_account_body'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Routes.myProfile);
                  },
                  child: Text(
                    'verify_now'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: Get.back,
                child: Text(
                  'skip'.tr,
                  style: const TextStyle(color: Colors.black45, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
