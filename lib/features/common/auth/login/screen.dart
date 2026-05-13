import 'package:sukientotapp/features/common/auth/login/controller.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/auth/widgets/terms_action_gate.dart';
import 'package:sukientotapp/features/common/auth/widgets/terms_acceptance_notice.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      child: Column(
        children: [
          // ── HERO SECTION ──────────────────────────────────────────
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Get.offAllNamed(Routes.guestHomeScreen),
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
                    Image.asset(AppImages.logo, width: 64, height: 64)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: -0.15, curve: Curves.easeOut),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                      'welcome_back'.tr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 400.ms)
                    .slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  'login_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── FORM SECTION ──────────────────────────────────────────
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
                child: Form(
                  key: controller.loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Username field
                      FTextFormField(
                            enabled: true,
                            control: FTextFieldControl.managed(
                              controller: controller.usernameController,
                            ),
                            label: Text('username'.tr),
                            hint: 'username_hint'.tr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) =>
                                (value != null && value.isNotEmpty)
                                ? null
                                : 'username_invalid'.tr,
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 16),

                      // Password field
                      FTextFormField.password(
                            control: FTextFieldControl.managed(
                              controller: controller.passwordController,
                            ),
                            label: Text('password'.tr),
                            hint: 'password_hint'.tr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) => 8 <= (value?.length ?? 0)
                                ? null
                                : 'password_invalid'.tr,
                          )
                          .animate()
                          .fadeIn(delay: 360.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),

                      // Forgot password – right-aligned
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(Routes.forgotPasswordScreen),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'forgot_password'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.fTheme.colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 420.ms, duration: 400.ms),

                      const SizedBox(height: 4),

                      // Login button
                      Obx(
                            () => TermsActionGate(
                              blocked:
                                  !controller.acceptedTerms.value &&
                                  !controller.isLoading.value,
                              onBlockedTap: controller.promptTermsAcceptance,
                              child: FButton(
                                onPress:
                                    controller.isLoading.value ||
                                        !controller.acceptedTerms.value
                                    ? null
                                    : controller.login,
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
                                          Text('logging_loading'.tr),
                                        ],
                                      )
                                    : Text('login'.tr),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 480.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),

                      const SizedBox(height: 24),

                      // ── OR divider ──
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.lightMutedForeground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ).animate().fadeIn(delay: 540.ms, duration: 400.ms),

                      const SizedBox(height: 24),

                      // Google button (outlined)
                      Obx(
                            () => TermsActionGate(
                              blocked:
                                  !controller.acceptedTerms.value &&
                                  !controller.isGoogleLoading.value,
                              onBlockedTap: controller.promptTermsAcceptance,
                              child: FButton(
                                style: FButtonStyle.outline(),
                                onPress:
                                    controller.isGoogleLoading.value ||
                                        !controller.acceptedTerms.value
                                    ? null
                                    : controller.loginWithGoogle,
                                prefix: controller.isGoogleLoading.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const FaIcon(
                                        FontAwesomeIcons.google,
                                        size: 16,
                                      ),
                                child: Text(
                                  controller.isGoogleLoading.value
                                      ? 'logging_loading'.tr
                                      : 'google_login'.tr,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      if (controller.canUseAppleLogin) ...[
                        const SizedBox(height: 12),
                        Obx(
                              () => TermsActionGate(
                                blocked:
                                    !controller.acceptedTerms.value &&
                                    !controller.isAppleLoading.value,
                                onBlockedTap: controller.promptTermsAcceptance,
                                child: FButton(
                                  style: FButtonStyle.outline(
                                    (style) => style.copyWith(
                                      decoration: FWidgetStateMap({
                                        WidgetState.disabled: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                        WidgetState.hovered |
                                            WidgetState.pressed: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.88,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                          ),
                                        ),
                                        WidgetState.any: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                          ),
                                        ),
                                      }),
                                      contentStyle: (contentStyle) =>
                                          contentStyle.copyWith(
                                            textStyle: FWidgetStateMap({
                                              WidgetState.disabled: contentStyle
                                                  .textStyle
                                                  .resolve({
                                                    WidgetState.disabled,
                                                  })
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                              WidgetState.any: contentStyle
                                                  .textStyle
                                                  .resolve({})
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            }),
                                            iconStyle: FWidgetStateMap({
                                              WidgetState.disabled: contentStyle
                                                  .iconStyle
                                                  .resolve({
                                                    WidgetState.disabled,
                                                  })
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                              WidgetState.any: contentStyle
                                                  .iconStyle
                                                  .resolve({})
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            }),
                                            circularProgressStyle:
                                                FWidgetStateMap({
                                                  WidgetState
                                                      .disabled: contentStyle
                                                      .circularProgressStyle
                                                      .resolve({
                                                        WidgetState.disabled,
                                                      })
                                                      .copyWith(
                                                        iconStyle:
                                                            const IconThemeData(
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                      ),
                                                  WidgetState.any: contentStyle
                                                      .circularProgressStyle
                                                      .resolve({})
                                                      .copyWith(
                                                        iconStyle:
                                                            const IconThemeData(
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                      ),
                                                }),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                          ),
                                    ),
                                  ),
                                  onPress:
                                      controller.isAppleLoading.value ||
                                          !controller.acceptedTerms.value
                                      ? null
                                      : controller.loginWithApple,
                                  prefix: controller.isAppleLoading.value
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const FaIcon(
                                          FontAwesomeIcons.apple,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                  child: Text(
                                    controller.isAppleLoading.value
                                        ? 'logging_loading'.tr
                                        : 'apple_login'.tr,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 660.ms, duration: 400.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOut),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
