import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/auth/register/controller.dart';
import 'package:sukientotapp/features/common/auth/register/widgets/partner_location_selector.dart';
import 'package:sukientotapp/features/common/auth/widgets/terms_action_gate.dart';
import 'package:sukientotapp/features/common/auth/widgets/terms_acceptance_notice.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

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
                      'create_account'.tr,
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
                  'register_subtitle'.tr,
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
              child: Form(
                key: controller.registerFormKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FTextFormField(
                            control: FTextFieldControl.managed(
                              controller: controller.nameController,
                            ),
                            label: Text('full_name'.tr),
                            hint: 'name_hint'.tr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) => (value?.isNotEmpty ?? false)
                                ? null
                                : 'name_invalid'.tr,
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 16),

                      FTextFormField(
                            control: FTextFieldControl.managed(
                              controller: controller.emailController,
                            ),
                            label: Text('email_address'.tr),
                            hint: 'email_hint'.tr,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) =>
                                (value?.contains('@') ?? false)
                                ? null
                                : 'email_invalid'.tr,
                          )
                          .animate()
                          .fadeIn(delay: 360.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 16),

                      FTextFormField(
                            control: FTextFieldControl.managed(
                              controller: controller.phoneController,
                            ),
                            label: Text('phone_number'.tr),
                            hint: 'phone_hint'.tr,
                            keyboardType: TextInputType.phone,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) => (value?.isNotEmpty ?? false)
                                ? null
                                : 'phone_invalid'.tr,
                          )
                          .animate()
                          .fadeIn(delay: 420.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),

                      if (!controller.isClientUser) ...[
                        const SizedBox(height: 16),
                        FTextFormField(
                              control: FTextFieldControl.managed(
                                controller: controller.cccdController,
                              ),
                              label: Text('identity_card_number'.tr),
                              hint: 'cccd_hint'.tr,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) => (value?.isNotEmpty ?? false)
                                  ? null
                                  : 'cccd_invalid'.tr,
                            )
                            .animate()
                            .fadeIn(delay: 480.ms, duration: 400.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOut),
                      ],

                      const SizedBox(height: 16),
                      FTextFormField.password(
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
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
                          .fadeIn(delay: 540.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
                      const SizedBox(height: 16),

                      FTextFormField.password(
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            autofocus: false,
                            control: FTextFieldControl.managed(
                              controller: controller.confirmPasswordController,
                            ),
                            label: Text('password_confirmation'.tr),
                            hint: 'password_confirmation_hint'.tr,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value != controller.passwordController.text) {
                                return 'password_mismatch_error'.tr;
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),

                      if (!controller.isClientUser) ...[
                        const SizedBox(height: 16),
                        const PartnerLocationSelector()
                            .animate()
                            .fadeIn(delay: 660.ms, duration: 400.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOut),
                      ],

                      const SizedBox(height: 20),
                      Obx(
                        () => TermsAcceptanceNotice(
                          value: controller.acceptedTerms.value,
                          onChanged: controller.toggleTermsAcceptance,
                        ),
                      ).animate().fadeIn(delay: 690.ms, duration: 400.ms),

                      const SizedBox(height: 28),
                      Obx(
                            () => TermsActionGate(
                              blocked: !controller.acceptedTerms.value &&
                                  !controller.isLoading.value,
                              onBlockedTap: controller.promptTermsAcceptance,
                              child: FButton(
                                onPress: controller.isLoading.value ||
                                        !controller.acceptedTerms.value
                                    ? null
                                    : controller.register,
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
                                          Text('creating_account_loading'.tr),
                                        ],
                                      )
                                    : Text('create_account_btn'.tr),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 720.ms, duration: 400.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOut),
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
