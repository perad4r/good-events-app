import 'dart:async';
import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';
import 'package:sukientotapp/features/common/home/controller.dart';

enum VerifyMethod { email, zalo }

class UserVerifyController extends GetxController {
  final AuthRepository _authRepository;

  UserVerifyController(this._authRepository);

  /// 1: method selection
  /// 2: OTP
  final step = 1.obs;

  final selectedMethod = Rx<VerifyMethod>(VerifyMethod.zalo);
  final otpController = TextEditingController();

  /// hide a small part of the info
  late final String maskedEmail;
  late final String maskedPhone;

  final isLoading = false.obs;
  final resendCooldown = 0.obs;
  final isMaxAttempts = false.obs;
  Timer? _cooldownTimer;

  // check client or partner
  bool get isClientUser => Get.find<GuestHomeController>().userType.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    maskedEmail = args?['masked_email'] ?? '**@***.com';
    maskedPhone = args?['masked_phone'] ?? '0**...***';
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  void selectMethod(VerifyMethod method) {
    selectedMethod.value = method;
  }

  Future<void> goToOtpStep() async {
    await _sendOtp();

    if (selectedMethod.value == VerifyMethod.email) {
      AppSnackbar.showSuccess(title: 'success'.tr, message: 'email_sent'.tr);
    } else {
      step.value = 2;
    }
  }

  void goBackToMethodStep() {
    step.value = 1;
    otpController.clear();
  }

  Future<void> verify() async {
    if (otpController.text.trim().length != 6) {
      AppSnackbar.showError(title: 'error'.tr, message: 'otp_invalid'.tr);
      return;
    }

    isLoading.value = true;
    try {
      if (selectedMethod.value == VerifyMethod.email) {
        // Email verification is handled via link sent to email — no OTP step here
        AppSnackbar.showSuccess(
          title: 'success'.tr,
          message: 'verify_success'.tr,
        );
      } else {
        await _authRepository.verifyOtp(otpController.text.trim());
        AppSnackbar.showSuccess(
          title: 'success'.tr,
          message: 'verify_success'.tr,
        );
      }
      Get.offAllNamed(isClientUser ? Routes.clientHome : Routes.partnerHome);
    } on OtpInvalidException {
      otpController.clear();
      AppSnackbar.showError(title: 'error'.tr, message: 'otp_invalid'.tr);
    } on OtpMaxAttemptsException catch (e) {
      isMaxAttempts.value = true;
      AppSnackbar.showError(title: 'error'.tr, message: e.message.tr);
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (resendCooldown.value > 0) return;
    await _sendOtp();
    AppSnackbar.showSuccess(title: 'success'.tr, message: 'otp_resent'.tr);
  }

  void _startCooldown([int seconds = 60]) {
    resendCooldown.value = seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value <= 1) {
        resendCooldown.value = 0;
        timer.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }

  /// decides which API to call based on [selectedMethod].
  /// call this when entering step 2 (goToOtpStep) or resending (resendOtp).
  Future<void> _sendOtp() async {
    isLoading.value = true;
    try {
      final method = selectedMethod.value == VerifyMethod.email
          ? 'email'
          : 'phone';
      await _authRepository.sendOtp(method);
      _startCooldown();
      AppSnackbar.showSuccess(title: 'success'.tr, message: 'otp_sent'.tr);
      logger.d('[UserVerifyController] OTP sent via $method');
    } on OtpCooldownException catch (e) {
      _startCooldown(e.retryAfter ?? 60);
      AppSnackbar.showError(
        title: 'error'.tr,
        message: e.message.trParams({
          'seconds': e.retryAfter?.toString() ?? '60',
        }),
      );
      rethrow;
    } on OtpMaxAttemptsException catch (e) {
      isMaxAttempts.value = true;
      AppSnackbar.showError(title: 'error'.tr, message: e.message.tr);
      rethrow;
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      rethrow; // prevent moving to step 2 if the send failed
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      if (StorageService.readData(key: LocalStorageKeys.token) == null) {
        StorageService.clearAllData();
        Get.offAllNamed(Routes.loginScreen);
        return;
      }

      await _authRepository.logout();
      StorageService.clearAllData();
      Get.offAllNamed(Routes.guestHomeScreen);
    } catch (e) {
      logger.e('[AccountController] [logout] error: $e');
      if (e.toString().contains('unauthorized')) {
        StorageService.clearAllData();
        Get.offAllNamed(Routes.guestHomeScreen);
        return;
      }
      AppSnackbar.showError(title: 'error'.tr, message: 'cannot_logout'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
