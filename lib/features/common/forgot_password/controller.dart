import 'dart:async';

import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';

enum ForgotMethod { email, phone }

class ForgotPasswordController extends GetxController {
  final AuthRepository _repository;

  ForgotPasswordController(this._repository);

  /// Steps:
  /// 1 = method selection
  /// 2 = input (email or phone)
  /// 3 = otp (phone) | email_sent notification (email)
  /// 4 = new password (phone only)
  final step = 1.obs;
  final selectedMethod = Rx<ForgotMethod>(ForgotMethod.phone);

  final inputController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final newPasswordFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;
  final resendCooldown = 0.obs;

  Timer? _cooldownTimer;

  /// Received from server after OTP verified – used to authorise password reset.
  String _resetToken = '';

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    inputController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void _startCooldown([int seconds = 120]) {
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

  void selectMethod(ForgotMethod method) {
    selectedMethod.value = method;
  }

  void goBack() {
    if (step.value > 1) {
      step.value = step.value - 1;
      if (step.value == 1) {
        inputController.clear();
      } else if (step.value == 2) {
        otpController.clear();
      }
    } else {
      Get.back();
    }
  }

  // ── Step 1 → 2 ──────────────────────────────────────────────────
  void goToInputStep() {
    step.value = 2;
  }

  // ── Step 2 → 3 ──────────────────────────────────────────────────
  Future<void> submitInput() async {
    final credential = inputController.text.trim();
    if (credential.isEmpty) return;

    isLoading.value = true;
    try {
      final method = selectedMethod.value == ForgotMethod.phone
          ? 'phone'
          : 'email';
      await _repository.forgotSendOtp(method: method, credential: credential);
      _startCooldown();
      step.value = 3;
    } on UserNotFoundException {
      AppSnackbar.showError(message: 'fp_user_not_found'.tr);
    } on OtpCooldownException catch (e) {
      final seconds = e.retryAfter;
      AppSnackbar.showError(
        message: seconds != null
            ? 'resend_otp_cooldown'.trParams({'seconds': seconds.toString()})
            : 'otp_cooldown'.tr,
      );
    } on OtpMaxAttemptsException catch (e) {
      final hours = e.retryAfter ?? 24;
      AppSnackbar.showError(
        message: 'otp_max_attempts'.trParams({'hours': hours.toString()}),
      );
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Step 3 – resend OTP ──────────────────────────────────────────
  Future<void> resendOtp() async {
    if (resendCooldown.value > 0) return;

    isLoading.value = true;
    try {
      await _repository.forgotSendOtp(
        method: 'phone',
        credential: inputController.text.trim(),
      );
      _startCooldown();
      AppSnackbar.showSuccess(message: 'otp_resent'.tr);
    } on OtpCooldownException catch (e) {
      final seconds = e.retryAfter;
      if (seconds != null) _startCooldown(seconds);
      AppSnackbar.showError(
        message: seconds != null
            ? 'resend_otp_cooldown'.trParams({'seconds': seconds.toString()})
            : 'otp_cooldown'.tr,
      );
    } on OtpMaxAttemptsException catch (e) {
      final hours = e.retryAfter ?? 24;
      AppSnackbar.showError(
        message: 'otp_max_attempts'.trParams({'hours': hours.toString()}),
      );
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Step 3 → 4 (phone only) ──────────────────────────────────────
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length < 6) return;

    isLoading.value = true;
    try {
      _resetToken = await _repository.forgotVerifyOtp(
        phone: inputController.text.trim(),
        otp: otp,
      );
      step.value = 4;
    } on OtpInvalidException {
      AppSnackbar.showError(message: 'otp_invalid'.tr);
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Step 4 – reset password ──────────────────────────────────────
  Future<void> resetPassword() async {
    if (!newPasswordFormKey.currentState!.validate()) return;
    final password = newPasswordController.text;
    if (password != confirmPasswordController.text) {
      AppSnackbar.showError(message: 'passwords_do_not_match'.tr);
      return;
    }

    isLoading.value = true;
    try {
      await _repository.forgotResetPassword(
        resetToken: _resetToken,
        password: password,
      );
      AppSnackbar.showSuccess(message: 'fp_reset_password_success'.tr);
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(Routes.guestHomeScreen);
      });
    } on InvalidTokenException {
      AppSnackbar.showError(message: 'fp_invalid_token'.tr);
    } on UserNotFoundException {
      AppSnackbar.showError(message: 'fp_user_not_found'.tr);
    } on PasswordValidationException catch (e) {
      final message = e.codes.map((code) => code.tr).join('\n');
      AppSnackbar.showError(message: message);
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;
  void toggleObscureConfirm() => obscureConfirm.value = !obscureConfirm.value;
}
