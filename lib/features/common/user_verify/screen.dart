import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/user_verify/controller.dart';
import 'widgets/verify_method_card.dart';

class UserVerifyScreen extends GetView<UserVerifyController> {
  const UserVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      child: Column(
        children: [
          // ── HERO SECTION ──────────────────────────────────────────
          Obx(() {
            final isOtpStep = controller.step.value == 2;
            final isEmail =
                controller.selectedMethod.value == VerifyMethod.email;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                36,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.red800, AppColors.red600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back / step indicator
                  if (isOtpStep)
                    GestureDetector(
                      onTap: controller.goBackToMethodStep,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms)
                  else
                    const SizedBox(height: 40),
                  const SizedBox(height: 20),
                  Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isOtpStep
                              ? (isEmail
                                    ? Icons.mark_email_read_rounded
                                    : Icons.sms_rounded)
                              : Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                      .animate(key: ValueKey(isOtpStep))
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: -0.1, curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Text(
                        isOtpStep
                            ? (isEmail
                                  ? 'verify_email_title'.tr
                                  : 'verify_phone_title'.tr)
                            : 'verify_account_title'.tr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate(key: ValueKey('title_$isOtpStep'))
                      .fadeIn(delay: 80.ms, duration: 350.ms)
                      .slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                        isOtpStep
                            ? (isEmail
                                  ? 'verify_email_otp_subtitle'.tr
                                  : 'verify_phone_otp_subtitle'.tr)
                            : 'verify_account_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      )
                      .animate(key: ValueKey('sub_$isOtpStep'))
                      .fadeIn(delay: 140.ms, duration: 350.ms),
                ],
              ),
            );
          }),

          // ── CONTENT SECTION ───────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.fTheme.colors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Obx(
                  () => controller.step.value == 1
                      ? _MethodSelectionStep(controller: controller)
                      : _OtpStep(controller: controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STEP 1: Choose method ─────────────────────────────────────────
class _MethodSelectionStep extends StatelessWidget {
  final UserVerifyController controller;
  const _MethodSelectionStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
              () => Column(
                children: [
                  VerifyMethodCard(
                    method: VerifyMethod.email,
                    selected:
                        controller.selectedMethod.value == VerifyMethod.email,
                    icon: Icons.mail_outline_rounded,
                    title: 'verify_via_email'.tr,
                    subtitle: controller.maskedEmail,
                    onTap: () => controller.selectMethod(VerifyMethod.email),
                  ),
                  const SizedBox(height: 12),
                  VerifyMethodCard(
                    method: VerifyMethod.zalo,
                    selected:
                        controller.selectedMethod.value == VerifyMethod.zalo,
                    icon: Icons.message_rounded,
                    title: 'verify_via_zalo'.tr,
                    subtitle: 'verify_zalo_subtitle'.trParams({
                      'phone': controller.maskedPhone,
                    }),
                    onTap: () => controller.selectMethod(VerifyMethod.zalo),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut),
        const SizedBox(height: 28),
        FButton(onPress: controller.goToOtpStep, child: Text('continue_btn'.tr))
            .animate()
            .fadeIn(delay: 320.ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
        const SizedBox(height: 20),
        Obx(
          () => controller.selectedMethod.value == VerifyMethod.email
              ? Column(
                  children: [
                    FButton(
                          onPress: controller.checkEmailVerificationStatus,
                          child: Text('check_verification_button'.tr),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),
                    const SizedBox(height: 20),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Center(
          child: TextButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: Text(
              'logout'.tr,
              style: TextStyle(
                fontSize: 13,
                color: context.fTheme.colors.mutedForeground,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
      ],
    );
  }
}

// ── STEP 2: Enter OTP ─────────────────────────────────────────────
class _OtpStep extends StatelessWidget {
  final UserVerifyController controller;
  const _OtpStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
              color: Colors.transparent,
              child: TextField(
                controller: controller.otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                autocorrect: false,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 14,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    color: context.fTheme.colors.mutedForeground,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.fTheme.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.fTheme.colors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 22),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut),
        const SizedBox(height: 24),
        Obx(
              () => FButton(
                onPress: controller.isLoading.value ? null : controller.verify,
                child: controller.isLoading.value
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('verifying'.tr),
                        ],
                      )
                    : Text('verify_btn'.tr),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
        const SizedBox(height: 20),
        Center(
          child: Obx(() {
            final cooldown = controller.resendCooldown.value;
            final maxAttempts = controller.isMaxAttempts.value;
            final canResend = cooldown == 0 && !maxAttempts;
            return TextButton.icon(
              onPressed: canResend ? controller.resendOtp : null,
              icon: Icon(
                maxAttempts
                    ? Icons.block_rounded
                    : canResend
                    ? Icons.refresh_rounded
                    : Icons.timer_outlined,
                size: 14,
              ),
              label: Text(
                maxAttempts
                    ? 'otp_max_attempts'.tr
                    : canResend
                    ? 'resend_otp'.tr
                    : 'resend_otp_cooldown'.trParams({
                        'seconds': cooldown.toString(),
                      }),
                style: TextStyle(
                  color: canResend
                      ? context.fTheme.colors.primary
                      : context.fTheme.colors.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
        const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout_rounded, size: 14),
              label: Text(
                'logout'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.goBackToMethodStep,
              child: Text(
                'back_to_method'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 440.ms, duration: 400.ms),
      ],
    );
  }
}
