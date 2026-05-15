import 'package:sukientotapp/core/utils/app_validators.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'controller.dart';
import 'widgets/forgot_method_card.dart';
import 'package:sukientotapp/features/common/auth/register/widgets/password_strength_checklist.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      child: Column(
        children: [
          // ── HERO SECTION ──────────────────────────────────────────
          Obx(() {
            final s = controller.step.value;
            final isPhone =
                controller.selectedMethod.value == ForgotMethod.phone;

            final (
              IconData heroIcon,
              String title,
              String subtitle,
            ) = switch (s) {
              1 => (
                Icons.lock_reset_rounded,
                'forgot_password'.tr,
                'forgot_password_subtitle'.tr,
              ),
              2 => (
                isPhone ? Icons.phone_android_rounded : Icons.email_rounded,
                isPhone ? 'fp_enter_phone_title'.tr : 'fp_enter_email_title'.tr,
                isPhone
                    ? 'fp_enter_phone_subtitle'.tr
                    : 'fp_enter_email_subtitle'.tr,
              ),
              3 => (
                isPhone ? Icons.sms_rounded : Icons.mark_email_read_rounded,
                isPhone ? 'fp_otp_title'.tr : 'fp_email_sent_title'.tr,
                isPhone ? 'fp_otp_subtitle'.tr : 'fp_email_sent_subtitle'.tr,
              ),
              _ => (
                Icons.lock_open_rounded,
                'fp_new_password_title'.tr,
                'fp_new_password_subtitle'.tr,
              ),
            };

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
                  // Back button
                  GestureDetector(
                    onTap: controller.goBack,
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
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                  // Step icon
                  Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(heroIcon, color: Colors.white, size: 28),
                      )
                      .animate(key: ValueKey('icon_$s'))
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: -0.15, curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate(key: ValueKey('title_$s'))
                      .fadeIn(delay: 180.ms, duration: 400.ms)
                      .slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      )
                      .animate(key: ValueKey('sub_$s'))
                      .fadeIn(delay: 250.ms, duration: 400.ms),

                  // Step progress dots
                  const SizedBox(height: 20),
                  _StepDots(currentStep: s, totalSteps: 4),
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
                child: Obx(() {
                  return switch (controller.step.value) {
                    1 => _MethodStep(controller: controller),
                    2 => _InputStep(controller: controller),
                    3 =>
                      controller.selectedMethod.value == ForgotMethod.phone
                          ? _OtpStep(controller: controller)
                          : _EmailSentStep(controller: controller),
                    _ => _NewPasswordStep(controller: controller),
                  };
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step dots indicator ───────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepDots({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i + 1 == currentStep;
        final done = i + 1 < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done || active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

// ── STEP 1: Choose method ─────────────────────────────────────────
class _MethodStep extends StatelessWidget {
  final ForgotPasswordController controller;
  const _MethodStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
              () => Column(
                children: [
                  ForgotMethodCard(
                    method: ForgotMethod.phone,
                    selected:
                        controller.selectedMethod.value == ForgotMethod.phone,
                    icon: Icons.phone_android_rounded,
                    title: 'fp_method_phone'.tr,
                    subtitle: 'fp_method_phone_subtitle'.tr,
                    onTap: () => controller.selectMethod(ForgotMethod.phone),
                  ),
                  const SizedBox(height: 12),
                  ForgotMethodCard(
                    method: ForgotMethod.email,
                    selected:
                        controller.selectedMethod.value == ForgotMethod.email,
                    icon: Icons.mail_outline_rounded,
                    title: 'fp_method_email'.tr,
                    subtitle: 'fp_method_email_subtitle'.tr,
                    onTap: () => controller.selectMethod(ForgotMethod.email),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut),
        const SizedBox(height: 28),
        FButton(
              onPress: controller.goToInputStep,
              child: Text('continue_btn'.tr),
            )
            .animate()
            .fadeIn(delay: 320.ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
      ],
    );
  }
}

// ── STEP 2: Enter phone / email ───────────────────────────────────
class _InputStep extends StatelessWidget {
  final ForgotPasswordController controller;
  const _InputStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPhone = controller.selectedMethod.value == ForgotMethod.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextFormField(
              control: FTextFieldControl.managed(
                controller: controller.inputController,
              ),
              label: Text(isPhone ? 'phone_number'.tr : 'email_address'.tr),
              hint: isPhone ? 'phone_hint'.tr : 'email_hint'.tr,
              keyboardType: isPhone
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut),
        const SizedBox(height: 24),
        Obx(
              () => FButton(
                onPress: controller.isLoading.value
                    ? null
                    : controller.submitInput,
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
                          Text('sending'.tr),
                        ],
                      )
                    : Text(
                        isPhone ? 'fp_send_otp'.tr : 'fp_send_reset_email'.tr,
                      ),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
      ],
    );
  }
}

// ── STEP 3a: Enter OTP (phone) ────────────────────────────────────
class _OtpStep extends StatelessWidget {
  final ForgotPasswordController controller;
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
                onPress: controller.isLoading.value
                    ? null
                    : controller.verifyOtp,
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
        const SizedBox(height: 16),
        Center(
          child: Obx(() {
            final cooldown = controller.resendCooldown.value;
            final canResend = cooldown == 0 && !controller.isLoading.value;
            return TextButton.icon(
              onPressed: canResend ? controller.resendOtp : null,
              icon: Icon(
                cooldown > 0 ? Icons.timer_outlined : Icons.refresh_rounded,
                size: 13,
              ),
              label: Text(
                cooldown > 0
                    ? 'resend_otp_cooldown'.trParams({
                        'seconds': cooldown.toString(),
                      })
                    : 'resend_otp'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: canResend
                      ? context.fTheme.colors.primary
                      : context.fTheme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
      ],
    );
  }
}

// ── STEP 3b: Email sent notification ─────────────────────────────
class _EmailSentStep extends StatelessWidget {
  final ForgotPasswordController controller;
  const _EmailSentStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.fTheme.colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.fTheme.colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 56,
                    color: context.fTheme.colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'fp_email_sent_card_title'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.fTheme.colors.foreground,
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut),
        const SizedBox(height: 24),
        // Info row: check spam
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: context.fTheme.colors.mutedForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'fp_email_spam_hint'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 320.ms, duration: 400.ms),
        const SizedBox(height: 28),
        FButton(onPress: Get.back, child: Text('fp_back_to_login'.tr))
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),
        const SizedBox(height: 12),
        Center(
          child: Obx(() {
            final cooldown = controller.resendCooldown.value;
            final canResend = cooldown == 0 && !controller.isLoading.value;
            return TextButton.icon(
              onPressed: canResend ? controller.resendOtp : null,
              icon: Icon(
                cooldown > 0 ? Icons.timer_outlined : Icons.refresh_rounded,
                size: 14,
              ),
              label: Text(
                cooldown > 0
                    ? 'resend_otp_cooldown'.trParams({
                        'seconds': cooldown.toString(),
                      })
                    : 'fp_resend_email'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: canResend
                      ? context.fTheme.colors.primary
                      : context.fTheme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ).animate().fadeIn(delay: 460.ms, duration: 400.ms),
      ],
    );
  }
}

// ── STEP 4: Enter new password (phone flow) ───────────────────────
class _NewPasswordStep extends StatelessWidget {
  final ForgotPasswordController controller;
  const _NewPasswordStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.newPasswordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTextFormField.password(
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                control: FTextFieldControl.managed(
                  controller: controller.newPasswordController,
                ),
                label: Text('new_password'.tr),
                hint: 'new_password_hint'.tr,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: AppValidators.validatePassword,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 8),
          PasswordStrengthChecklist(
            controller: controller.newPasswordController,
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
          const SizedBox(height: 16),
          FTextFormField.password(
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                autofocus: false,
                control: FTextFieldControl.managed(
                  controller: controller.confirmPasswordController,
                ),
                label: Text('confirm_new_password'.tr),
                hint: 'confirm_new_password_hint'.tr,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value != controller.newPasswordController.text) {
                    return 'password_mismatch_error'.tr;
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 280.ms, duration: 400.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),
          const SizedBox(height: 24),
          Obx(
                () => FButton(
                  onPress: controller.isLoading.value
                      ? null
                      : controller.resetPassword,
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
                            Text('resetting_password'.tr),
                          ],
                        )
                      : Text('fp_confirm_new_password'.tr),
                ),
              )
              .animate()
              .fadeIn(delay: 360.ms, duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
