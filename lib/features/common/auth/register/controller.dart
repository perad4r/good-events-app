import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';
import 'package:sukientotapp/domain/repositories/location_repository.dart';
import 'package:sukientotapp/features/common/home/controller.dart';
import 'package:sukientotapp/data/models/location_model.dart';

class RegisterController extends GetxController {
  final AuthRepository _authRepository;
  final LocationRepository _locationRepository;

  RegisterController(this._authRepository, this._locationRepository);

  final registerFormKey = GlobalKey<FormState>();

  // check client or partner
  bool get isClientUser => Get.find<GuestHomeController>().userType.value;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // only for partner
  final cccdController = TextEditingController();

  final provinces = <LocationModel>[].obs;
  final wards = <LocationModel>[].obs;
  final selectedProvince = Rx<LocationModel?>(null);
  final selectedWard = Rx<LocationModel?>(null);

  final isFetchingProvinces = false.obs;
  final isFetchingWards = false.obs;

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final acceptedTerms = false.obs;

  @override
  void onInit() {
    super.onInit();

    // only fetch when it's the partner form
    ever(Get.find<GuestHomeController>().userType, (bool isClient) {
      if (!isClient && provinces.isEmpty) {
        fetchProvinces();
      }
    });

    if (!isClientUser && provinces.isEmpty) {
      fetchProvinces();
    }
  }

  @override
  void onClose() {
    super.onClose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    cccdController.dispose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void toggleTermsAcceptance(bool value) {
    acceptedTerms.value = value;
  }

  Future<void> promptTermsAcceptance() async {
    if (acceptedTerms.value) {
      return;
    }

    final accepted = await Get.dialog<bool>(
      AlertDialog(
        title: Text('terms_prompt_title'.tr),
        content: Text('terms_prompt_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('terms_prompt_accept'.tr),
          ),
        ],
      ),
    );

    if (accepted == true) {
      acceptedTerms.value = true;
    }
  }

  bool _ensureTermsAccepted() {
    if (acceptedTerms.value) {
      return true;
    }
    promptTermsAcceptance();
    return false;
  }

  Future<void> fetchProvinces() async {
    try {
      isFetchingProvinces.value = true;
      final data = await _locationRepository.getProvinces();
      provinces.assignAll(data);
    } catch (e) {
      logger.e('[RegisterController] Error fetching provinces: $e');
      Get.snackbar('error'.tr, 'failed_to_load_provinces'.tr);
    } finally {
      isFetchingProvinces.value = false;
    }
  }

  Future<void> fetchWards(int provinceId) async {
    try {
      isFetchingWards.value = true;
      wards.clear();
      final data = await _locationRepository.getWards(provinceId);
      wards.assignAll(data);
    } catch (e) {
      logger.e('[RegisterController] Error fetching wards: $e');
      Get.snackbar('error'.tr, 'failed_to_load_wards'.tr);
    } finally {
      isFetchingWards.value = false;
    }
  }

  void selectProvince(LocationModel province) {
    if (selectedProvince.value?.id != province.id) {
      selectedProvince.value = province;
      selectedWard.value = null; // reset ward when province changes
      fetchWards(province.id);
    }
  }

  void selectWard(LocationModel ward) {
    selectedWard.value = ward;
  }

  Future<void> register() async {
    if (!_ensureTermsAccepted()) {
      return;
    }

    registerFormKey.currentState!.save();

    if (!registerFormKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('error'.tr, 'password_mismatch_error'.tr);
      return;
    }

    if (!isClientUser) {
      if (selectedProvince.value == null || selectedWard.value == null) {
        Get.snackbar('error'.tr, 'please_select_location'.tr);
        return;
      }
    }

    try {
      isLoading.value = true;

      if (isClientUser) {
        /// Client register
        final payload = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        };
        await _authRepository.registerClient(payload);
      } else {
        /// Partner register
        final payload = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'identity_card_number': cccdController.text.trim(),
          'ward_id': selectedWard.value!.id,
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        };
        await _authRepository.registerPartner(payload);
      }

      // Get.snackbar('success'.tr, 'register_successful'.tr);
      // fake delay
      await Future.delayed(const Duration(milliseconds: 800));

      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final maskedEmail = _maskEmail(email);
      final maskedPhone = _maskPhone(phone);

      Get.offNamed(
        Routes.userVerifyScreen,
        arguments: {'masked_email': maskedEmail, 'masked_phone': maskedPhone},
      );
    } catch (e) {
      logger.e('[RegisterController] Registration failed: $e');
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// hide the full email like "myemai****@something.com"
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    final visible = local.length > 2 ? local.substring(0, 2) : local;
    return '$visible${'*' * (local.length - visible.length)}@$domain';
  }

  /// hide the full phone like "012****345"
  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    final start = phone.substring(0, 3);
    final end = phone.substring(phone.length - 3);
    return '$start${'*' * (phone.length - 6)}$end';
  }
}
