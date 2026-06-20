import 'package:dio/dio.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/common/profile_model.dart';
import 'package:sukientotapp/data/models/location_model.dart';
import 'package:sukientotapp/data/providers/location_provider.dart';
import 'package:sukientotapp/domain/repositories/common/my_profile_repository.dart';
import 'package:sukientotapp/features/common/account/controller.dart';
import 'package:sukientotapp/features/partner/home/controller.dart'
    as partner_home;
import 'package:sukientotapp/features/client/home/controller.dart'
    as client_home;

import 'controller.dart';

class EditProfileController extends GetxController {
  final MyProfileRepository _repository;
  final LocationProvider _locationProvider;

  EditProfileController(this._repository, this._locationProvider);

  static const int _maxProfileImageSizeBytes = 10 * 1024 * 1024;
  static const Set<String> _allowedProfileImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  late final ProfileModel initialProfile;

  // Text controllers
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController countryCodeController;
  late final TextEditingController phoneController;
  late final QuillController quillBioController;
  final FocusNode bioFocusNode = FocusNode();
  final ScrollController bioScrollController = ScrollController();
  late final TextEditingController partnerNameController;
  late final TextEditingController identityCardController;
  late final TextEditingController videoUrlController;

  // Image files
  final avatarFile = Rxn<XFile>();
  final selfieFile = Rxn<XFile>();
  final frontCardFile = Rxn<XFile>();
  final backCardFile = Rxn<XFile>();

  // Location
  final provinces = <LocationModel>[].obs;
  final wards = <LocationModel>[].obs;
  final selectedProvince = Rxn<LocationModel>();
  final selectedWard = Rxn<LocationModel>();
  final isLoadingWards = false.obs;
  final isUpdating = false.obs;

  RxString get role => Get.find<MyProfileController>().role;

  @override
  void onInit() {
    super.onInit();
    initialProfile = Get.arguments as ProfileModel;

    nameController = TextEditingController(text: initialProfile.name);
    emailController = TextEditingController(text: initialProfile.email);
    countryCodeController = TextEditingController();
    phoneController = TextEditingController(text: initialProfile.phone);

    // Initialize Quill editor with existing HTML bio content
    Document bioDocument;
    if (initialProfile.bio.isNotEmpty) {
      try {
        final delta = HtmlToDelta().convert(initialProfile.bio);
        bioDocument = Document.fromDelta(delta);
      } catch (_) {
        bioDocument = Document();
      }
    } else {
      bioDocument = Document();
    }
    quillBioController = QuillController(
      document: bioDocument,
      selection: const TextSelection.collapsed(offset: 0),
    );

    partnerNameController = TextEditingController(
      text: initialProfile.partnerName ?? '',
    );
    identityCardController = TextEditingController(
      text: initialProfile.identityCardNumber ?? '',
    );
    videoUrlController = TextEditingController(
      text: initialProfile.videoUrl,
    );

    if (role.value == 'partner') {
      fetchLocations();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    countryCodeController.dispose();
    phoneController.dispose();
    quillBioController.dispose();
    bioFocusNode.dispose();
    bioScrollController.dispose();
    partnerNameController.dispose();
    identityCardController.dispose();
    videoUrlController.dispose();
    super.onClose();
  }

  Future<void> fetchLocations() async {
    try {
      final data = await _locationProvider.getProvinces();
      final list = data
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      provinces.assignAll(list);

      if (initialProfile.locationId != null) {
        final matching = list.where((l) => l.id == initialProfile.locationId);
        if (matching.isNotEmpty) {
          selectedProvince.value = matching.first;
          await fetchWards(matching.first.id);
        }
      }
    } catch (e) {
      logger.e('[EditProfileController] [fetchLocations] error: $e');
    }
  }

  Future<void> fetchWards(int provinceId) async {
    try {
      isLoadingWards.value = true;
      wards.clear();
      selectedWard.value = null;
      final data = await _locationProvider.getWards(provinceId);
      final list = data
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      wards.assignAll(list);
    } catch (e) {
      logger.e('[EditProfileController] [fetchWards] error: $e');
    } finally {
      isLoadingWards.value = false;
    }
  }

  void onProvinceChanged(LocationModel province) {
    selectedProvince.value = province;
    fetchWards(province.id);
  }

  String _getBioHtml() {
    final deltaJson = quillBioController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
      List<Map<String, dynamic>>.from(deltaJson),
    );
    return converter.convert();
  }

  Future<void> pickImage(String type) async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;
    if (!await validateProfileImage(image, isAvatar: type == 'avatar')) return;

    switch (type) {
      case 'avatar':
        avatarFile.value = image;
        break;
      case 'selfie':
        selfieFile.value = image;
        break;
      case 'front_card':
        frontCardFile.value = image;
        break;
      case 'back_card':
        backCardFile.value = image;
        break;
    }
  }

  Future<bool> validateProfileImage(
    XFile image, {
    bool isAvatar = false,
  }) async {
    final extension = image.name.split('.').last.toLowerCase();
    if (!_allowedProfileImageExtensions.contains(extension)) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'image_format_not_supported'.tr,
      );
      return false;
    }

    final size = await image.length();
    if (size > _maxProfileImageSizeBytes) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: isAvatar
            ? 'avatar_image_too_large'.tr
            : 'profile_image_too_large'.tr,
      );
      return false;
    }

    return true;
  }

  Future<void> isUpdateId() async {
    if (role.value == 'partner' &&
        (selfieFile.value != null ||
            frontCardFile.value != null ||
            backCardFile.value != null)) {
      _showUpdateNotification();
    } else {
      updateProfile();
    }
  }

  Future<void> updateProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      AppSnackbar.showError(message: 'name_required'.tr);
      return;
    }
    if (email.isEmpty) {
      AppSnackbar.showError(message: 'email_required'.tr);
      return;
    }

    try {
      isUpdating.value = true;

      final Map<String, dynamic> formDataMap = {
        'name': name,
        'email': email,
        'phone': phoneController.text.trim(),
        'bio': _getBioHtml(),
        'video_url': videoUrlController.text.trim(),
      };

      if (role.value == 'partner') {
        formDataMap['partner_name'] = partnerNameController.text.trim();
        formDataMap['identity_card_number'] = identityCardController.text
            .trim();
        if (selectedWard.value != null) {
          formDataMap['location_id'] = selectedWard.value!.id;
        } else if (selectedProvince.value != null) {
          formDataMap['location_id'] = selectedProvince.value!.id;
        }
      }

      if (avatarFile.value != null) {
        formDataMap['avatar'] = await MultipartFile.fromFile(
          avatarFile.value!.path,
          filename: avatarFile.value!.name,
        );
      }

      if (role.value == 'partner') {
        if (selfieFile.value != null) {
          formDataMap['selfie_image'] = await MultipartFile.fromFile(
            selfieFile.value!.path,
            filename: selfieFile.value!.name,
          );
        }
        if (frontCardFile.value != null) {
          formDataMap['front_identity_card_image'] =
              await MultipartFile.fromFile(
                frontCardFile.value!.path,
                filename: frontCardFile.value!.name,
              );
        }
        if (backCardFile.value != null) {
          formDataMap['back_identity_card_image'] =
              await MultipartFile.fromFile(
                backCardFile.value!.path,
                filename: backCardFile.value!.name,
              );
        }
      }

      final formData = FormData.fromMap(formDataMap);
      final updatedProfile = await _repository.updateProfile(formData);

      await Get.find<MyProfileController>().fetchProfile();

      StorageService.updateMapData(
        key: LocalStorageKeys.user,
        mapKey: 'name',
        value: name,
      );

      StorageService.updateMapData(
        key: LocalStorageKeys.user,
        mapKey: 'avatar_url',
        value: updatedProfile.avatarUrl,
      );

      if (Get.isRegistered<AccountController>()) {
        Get.find<AccountController>().syncFromStorage();
      }

      if (role.value == 'partner') {
        if (Get.isRegistered<partner_home.PartnerHomeController>()) {
          Get.find<partner_home.PartnerHomeController>().syncFromStorage();
        }
      } else {
        if (Get.isRegistered<client_home.ClientHomeController>()) {
          Get.find<client_home.ClientHomeController>().syncFromStorage();
        }
      }

      AppSnackbar.showSuccess(message: 'profile_updated'.tr);
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      logger.e('[EditProfileController] [updateProfile] error: $e');
      AppSnackbar.showError(message: 'update_failed'.tr);
    } finally {
      isUpdating.value = false;
    }
  }

  void _showUpdateNotification() {
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'upload_id_notification'.tr,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    updateProfile();
                  },
                  child: Text(
                    'update'.tr,
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
                  'cancel'.tr,
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
