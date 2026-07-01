import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/location_model.dart';
import 'package:sukientotapp/data/models/partner/service_area_model.dart';
import 'package:sukientotapp/domain/repositories/location_repository.dart';
import 'package:sukientotapp/domain/repositories/partner/service_area_repository.dart';
import 'package:sukientotapp/features/partner/new_show/controller.dart';

class PartnerServiceAreasController extends GetxController {
  final PartnerServiceAreaRepository _repository;
  final LocationRepository _locationRepository;

  PartnerServiceAreasController(this._repository, this._locationRepository);

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isLoadingWards = false.obs;
  final provinces = <LocationModel>[].obs;
  final wards = <LocationModel>[].obs;
  final selectedProvince = Rxn<LocationModel>();
  final serviceAreas = <PartnerServiceAreaModel>[].obs;
  final selectedLocationIds = <int>[].obs;
  final selectionVersion = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _repository.getServiceAreas(),
        _locationRepository.getProvinces(),
      ]);

      final areaResponse = results[0] as PartnerServiceAreasResponse;
      final provinceList = results[1] as List<LocationModel>;

      serviceAreas.assignAll(areaResponse.serviceAreas);
      selectedLocationIds.assignAll(areaResponse.serviceAreaLocationIds);
      provinces.assignAll(provinceList);

      if (serviceAreas.isNotEmpty) {
        final firstProvinceId = serviceAreas.first.provinceId;
        final matching = provinceList.where((p) => p.id == firstProvinceId);
        if (matching.isNotEmpty) {
          await onProvinceChanged(matching.first);
        }
      }
    } catch (e) {
      logger.e('[PartnerServiceAreasController] [loadInitialData] $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onProvinceChanged(LocationModel province) async {
    selectedProvince.value = province;
    await fetchWards(province.id);
  }

  Future<void> fetchWards(int provinceId) async {
    try {
      isLoadingWards.value = true;
      wards.clear();
      final data = await _locationRepository.getWards(provinceId);
      wards.assignAll(data);
    } catch (e) {
      logger.e('[PartnerServiceAreasController] [fetchWards] $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoadingWards.value = false;
    }
  }

  void toggleWard(LocationModel ward) {
    if (selectedLocationIds.contains(ward.id)) {
      selectedLocationIds.remove(ward.id);
      serviceAreas.removeWhere((area) => area.id == ward.id);
      _notifySelectionChanged();
      return;
    }

    selectedLocationIds.add(ward.id);
    _addServiceAreaFromWard(ward);
    _notifySelectionChanged();
  }

  void removeServiceArea(int locationId) {
    selectedLocationIds.remove(locationId);
    serviceAreas.removeWhere((area) => area.id == locationId);
    _notifySelectionChanged();
  }

  bool get areAllCurrentWardsSelected {
    if (wards.isEmpty) return false;
    return wards.every((ward) => selectedLocationIds.contains(ward.id));
  }

  void selectAllCurrentWards() {
    for (final ward in wards) {
      if (!selectedLocationIds.contains(ward.id)) {
        selectedLocationIds.add(ward.id);
        _addServiceAreaFromWard(ward);
      }
    }
    _notifySelectionChanged();
  }

  void clearCurrentProvinceWards() {
    final wardIds = wards.map((ward) => ward.id).toSet();
    selectedLocationIds.removeWhere(wardIds.contains);
    serviceAreas.removeWhere((area) => wardIds.contains(area.id));
    _notifySelectionChanged();
  }

  Future<void> clearAll() async {
    selectedLocationIds.clear();
    serviceAreas.clear();
    _notifySelectionChanged();
    await saveServiceAreas();
  }

  Future<void> saveServiceAreas() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;
      final response = await _repository.updateServiceAreas(
        selectedLocationIds.toList(),
      );
      selectedLocationIds.assignAll(response.serviceAreaLocationIds);
      serviceAreas.assignAll(response.serviceAreas);
      _notifySelectionChanged();
      await _reloadNewShows();
      AppSnackbar.showSuccess(
        title: 'success'.tr,
        message: 'service_areas_saved'.tr,
      );
    } catch (e) {
      logger.e('[PartnerServiceAreasController] [saveServiceAreas] $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void _addServiceAreaFromWard(LocationModel ward) {
    if (serviceAreas.any((area) => area.id == ward.id)) return;

    final province = selectedProvince.value;
    serviceAreas.add(
      PartnerServiceAreaModel(
        id: ward.id,
        name: ward.name,
        provinceId: province?.id ?? ward.parentId ?? 0,
        provinceName: province?.name ?? '',
      ),
    );
  }

  void _notifySelectionChanged() {
    selectionVersion.value++;
  }

  Future<void> _reloadNewShows() async {
    if (!Get.isRegistered<NewShowController>()) return;
    await Get.find<NewShowController>().reloadAfterServiceAreasChanged();
  }
}
