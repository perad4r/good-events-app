import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/service_model.dart';
import 'package:sukientotapp/domain/repositories/partner/my_services_repository.dart';
import 'widgets/edit_service_sheet.dart';
import 'widgets/add_service_sheet.dart';
import 'widgets/manage_service_media_sheet.dart';

class ServiceMediaEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void dispose() {
    nameController.dispose();
    urlController.dispose();
    descriptionController.dispose();
  }

  Map<String, dynamic> toJson() => {
    'name': nameController.text.trim(),
    'url': urlController.text.trim(),
    'description': descriptionController.text.trim(),
  };
}

class MyServicesController extends GetxController {
  final MyServicesRepository _repository;
  MyServicesController(this._repository);

  final isLoading = false.obs;
  final services = <ServiceModel>[].obs;
  RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

  // Edit sheet state
  final isSheetLoading = false.obs;
  final isSaving = false.obs;
  final sheetDetail = Rxn<ServiceDetailModel>();
  final categories = <ServiceCategoryModel>[].obs;
  final selectedCategoryId = ''.obs;

  // Add sheet state
  final isAddSheetLoading = false.obs;
  final isCreating = false.obs;
  final addSelectedCategoryId = ''.obs;
  final addMediaEntries = <ServiceMediaEntry>[].obs;

  // Manage media state
  final isMediaLoading = false.obs;
  final isUploadingImages = false.obs;
  final serviceImages = <ServiceImageModel>[].obs;
  String _mediaServiceId = '';

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  void onRefresh() async {
    try {
      services.value = await _repository.getServices();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      refreshController.refreshCompleted();
    }
  }

  void onLoadMore() async {
    refreshController.loadComplete();
  }

  Future<void> fetchServices() async {
    try {
      isLoading.value = true;
      services.value = await _repository.getServices();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openEditSheet(ServiceModel service) async {
    sheetDetail.value = null;
    selectedCategoryId.value = service.categoryId;
    isSheetLoading.value = true;

    Get.bottomSheet(
      const EditServiceSheet(),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 250),
    );

    try {
      final results = await Future.wait([
        _repository.getServiceDetail(service.id),
        _repository.getServiceCategories(),
      ]);
      sheetDetail.value = results[0] as ServiceDetailModel;
      final allCategories = results[1] as List<ServiceCategoryModel>;

      final usedIds = services
          .where((s) => s.id != service.id)
          .map((s) => s.categoryId)
          .toSet();
      categories.value = allCategories
          .where((c) => !usedIds.contains(c.id))
          .toList();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      Get.back();
    } finally {
      isSheetLoading.value = false;
    }
  }

  Future<void> saveService() async {
    final detail = sheetDetail.value;
    if (detail == null) return;
    if (selectedCategoryId.value.isEmpty) return;

    try {
      isSaving.value = true;
      await _repository.updateService(detail.id, selectedCategoryId.value);
      AppSnackbar.showSuccess(
        title: 'success'.tr,
        message: 'profile_updated'.tr,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
      await fetchServices();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Add service ────────────────────────────────────────────────────────────

  Future<void> openAddSheet() async {
    addSelectedCategoryId.value = '';
    for (final e in addMediaEntries) {
      e.dispose();
    }
    addMediaEntries.clear();
    isAddSheetLoading.value = true;

    Get.bottomSheet(
      const AddServiceSheet(),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 250),
    );

    try {
      final allCategories = await _repository.getServiceCategories();
      final usedIds = services.map((s) => s.categoryId).toSet();
      categories.value = allCategories
          .where((c) => !usedIds.contains(c.id))
          .toList();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      Get.back();
    } finally {
      isAddSheetLoading.value = false;
    }
  }

  void addMediaEntry() => addMediaEntries.add(ServiceMediaEntry());

  void removeMediaEntry(int index) {
    addMediaEntries[index].dispose();
    addMediaEntries.removeAt(index);
  }

  Future<void> submitCreateService() async {
    if (addSelectedCategoryId.value.isEmpty) {
      AppSnackbar.showError(title: 'error'.tr, message: 'select_category'.tr);
      return;
    }

    if (addMediaEntries.isEmpty) {
      AppSnackbar.showError(title: 'error'.tr, message: 'media_required'.tr);
      return;
    }

    final mediaList = addMediaEntries
        .map((e) => e.toJson())
        .where((m) => (m['url'] as String).isNotEmpty)
        .toList();

    try {
      isCreating.value = true;
      await _repository.createService(addSelectedCategoryId.value, mediaList);
      AppSnackbar.showSuccess(
        title: 'success'.tr,
        message: 'service_created'.tr,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
      for (final e in addMediaEntries) {
        e.dispose();
      }
      addMediaEntries.clear();
      await fetchServices();
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isCreating.value = false;
    }
  }

  // ─── Manage service images ───────────────────────────────────────────────────

  Future<void> openManageMediaSheet(ServiceModel service) async {
    _mediaServiceId = service.id;
    serviceImages.clear();
    isMediaLoading.value = true;

    Get.bottomSheet(
      const ManageServiceMediaSheet(),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 250),
    );

    try {
      serviceImages.value = await _repository.getServiceImages(service.id);
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      Get.back();
    } finally {
      isMediaLoading.value = false;
    }
  }

  Future<void> pickAndUploadImages() async {
    if (serviceImages.length >= 10) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'images_limit_reached'.tr,
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    const maxSizeBytes = 20 * 1024 * 1024; // 20 MB
    final remaining = 10 - serviceImages.length;
    final candidates = picked.take(remaining).toList();

    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

    final validImages = <XFile>[];
    for (final img in candidates) {
      final ext = img.name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        AppSnackbar.showError(
          title: 'error'.tr,
          message: 'image_format_not_supported'.tr,
        );
        continue;
      }
      final bytes = await img.length();
      if (bytes > maxSizeBytes) {
        AppSnackbar.showError(title: 'error'.tr, message: 'image_too_large'.tr);
      } else {
        validImages.add(img);
      }
    }
    if (validImages.isEmpty) return;

    try {
      isUploadingImages.value = true;
      final newImages = await _repository.uploadServiceImages(
        _mediaServiceId,
        validImages,
      );
      serviceImages.addAll(newImages);
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isUploadingImages.value = false;
    }
  }

  Future<void> deleteServiceImage(String imageId) async {
    try {
      await _repository.deleteServiceImage(_mediaServiceId, imageId);
      serviceImages.removeWhere((img) => img.id == imageId);
    } catch (e) {
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    }
  }
}
