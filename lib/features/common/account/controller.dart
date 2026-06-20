import 'package:sukientotapp/core/utils/import/global.dart';

import 'package:sukientotapp/data/models/partner/wallet_transaction_model.dart';
import 'package:sukientotapp/domain/repositories/partner/account_repository.dart';

class AccountController extends GetxController {
  final AccountRepository _repository;
  AccountController(this._repository);

  final isLoading = false.obs;

  //============================================================================
  // PERSONAL INFORMATION
  //============================================================================
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

  RxString role =
      (StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'role') ??
              '')
          .toString()
          .obs;
  final RxBool saveBankInfo = false.obs;

  RxString isHavePartnerProfile =
      (StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'is_have_partner_profile',
              ) ??
              '')
          .toString()
          .obs;

  //============================================================================
  // WALLET & TRANSACTIONS
  //============================================================================
  RxInt balance = RxInt(
    (StorageService.readMapData(
              key: LocalStorageKeys.user,
              mapKey: 'wallet_balance',
            )
            as int?) ??
        0,
  );
  final filterDate = DateTime.now().obs;
  final RxInt selectedBank =
      1.obs; //currently we only support PayOs, so default to 1
  final RxBool isRechargeAmountError = false.obs;
  final TextEditingController rechargeAmount = TextEditingController();
  final RxList<WalletTransactionModel> walletTransactions =
      <WalletTransactionModel>[].obs;
  final RxBool isTransactionsLoading = false.obs;

  //============================================================================
  // CARD INFORMATION
  //============================================================================
  final TextEditingController cardName = TextEditingController();
  final RxBool isCardNameError = false.obs;
  final TextEditingController cardNumber = TextEditingController();
  final RxBool isCardNumberError = false.obs;
  final TextEditingController cardExpiry = TextEditingController();
  final RxBool isCardExpiryError = false.obs;
  final TextEditingController cardCvv = TextEditingController();
  final RxBool isCardCvvError = false.obs;

  final List<Map<String, dynamic>> bankAccounts = [
    {
      'id': 1,
      'bank': 'PayOs',
      'number': 'Nạp qua mã QR',
      'expiry': 'N/A',
      'name': 'PayOs',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    if (role.value == 'partner') {
      fetchWalletTransactions();
    }
  }

  Future<void> onRefresh() async {
    if (role.value == 'partner') {
      await fetchWalletTransactions();
    }
  }

  Future<void> onLoadMore() async {}

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

  //============================================================================
  // CARD VALIDATION METHODS
  //============================================================================
  void checkCardInfo() {
    _validateCardName();
    _validateCardNumber();
    _validateCardExpiry();
    _validateCardCvv();
  }

  void _validateCardName() {
    isCardNameError.value = cardName.text.isEmpty;
  }

  void _validateCardNumber() {
    isCardNumberError.value = cardNumber.text.isEmpty;
  }

  void _validateCardExpiry() {
    isCardExpiryError.value = cardExpiry.text.isEmpty;
  }

  void _validateCardCvv() {
    isCardCvvError.value = cardCvv.text.isEmpty;
  }

  //============================================================================
  // HELPER METHODS
  //============================================================================
  Future<void> fetchWalletTransactions() async {
    try {
      isTransactionsLoading.value = true;
      final transactions = await _repository.getWalletTransactions();
      walletTransactions.value = transactions;
    } catch (e) {
      logger.e('[AccountController] fetchWalletTransactions: $e');
      AppSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  void filterTransactionsByDate(DateTime date) {
    filterDate.value = date;
    // Add logic to filter transactions by date
  }

  String formatPrice(int price) {
    final formatted = NumberFormat('#,##0', 'en_US').format(price);
    return '$formatted ${"currency".tr}';
  }

  //============================================================================
  // WALLET RECHARGE
  //============================================================================
  final RxBool isRechargeLoading = false.obs;

  Future<void> rechargeWallet() async {
    final rawText = rechargeAmount.text;
    final digits = rawText.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits);

    if (amount == null || amount <= 0) {
      isRechargeAmountError.value = true;
      return;
    }
    isRechargeAmountError.value = false;

    try {
      isRechargeLoading.value = true;
      final checkoutUrl = await _repository.regenerateAddFundsLink(
        amount.toInt(),
      );
      rechargeAmount.clear();
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
      Get.toNamed(
        Routes.webView,
        arguments: {'url': checkoutUrl, 'title': 'add_balance'.tr},
      );
    } catch (e) {
      logger.e('[AccountController] [rechargeWallet] error: $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isRechargeLoading.value = false;
    }
  }

  //============================================================================
  // ROLE SWITCHING
  //============================================================================
  static DateTime? _lastSwitchTime;

  Future<void> switchRole() async {
    if (isHavePartnerProfile.value == 'false') {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'no_partner_profile'.tr,
      );
      return;
    }

    final now = DateTime.now();
    if (_lastSwitchTime != null &&
        now.difference(_lastSwitchTime!).inSeconds < 3) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'switch_role_too_fast'.tr,
      );
      return;
    }
    if (isLoading.value) return;

    _lastSwitchTime = now;
    isLoading.value = true;

    try {
      final newRole = role.value == 'partner' ? 'client' : 'partner';

      StorageService.updateMapData(
        key: LocalStorageKeys.user,
        mapKey: 'role',
        value: newRole,
      );

      if (newRole == 'client') {
        Get.offAllNamed(Routes.clientHome);

        StorageService.writeStringData(
          key: LocalStorageKeys.currentUIView,
          value: 'client',
        );
      } else {
        Get.offAllNamed(Routes.partnerHome);

        StorageService.writeStringData(
          key: LocalStorageKeys.currentUIView,
          value: 'partner',
        );
      }
    } catch (e) {
      logger.e('[AccountController] [switchRole] error: $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      isLoading.value = false;
    }
  }

  //============================================================================
  // AUTHENTICATION
  //============================================================================
  final TextEditingController deletePasswordController =
      TextEditingController();
  final RxBool isDeletePasswordObscure = true.obs;

  Future<void> deleteAccount() async {
    final password = deletePasswordController.text.trim();
    if (password.isEmpty) {
      AppSnackbar.showError(title: 'error'.tr, message: 'password_required'.tr);
      return;
    }
    isLoading.value = true;
    try {
      await _repository.deleteAccount(password);
      deletePasswordController.clear();
      StorageService.clearAllData();
      Get.offAllNamed(Routes.loginScreen);
    } catch (e) {
      logger.e('[AccountController] [deleteAccount] error: $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      if (StorageService.readData(key: LocalStorageKeys.token) == null) {
        StorageService.clearAllData();
        Get.offAllNamed(Routes.loginScreen);
        return;
      }

      await _repository.logout();
      StorageService.clearAllData();
      Get.offAllNamed(Routes.loginScreen);
    } catch (e) {
      logger.e('[AccountController] [logout] error: $e');
      if (e.toString().contains('unauthorized')) {
        StorageService.clearAllData();
        Get.offAllNamed(Routes.loginScreen);
        return;
      }
      AppSnackbar.showError(title: 'error'.tr, message: 'cannot_logout'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
