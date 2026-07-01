import 'package:get/get.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/providers/location_provider.dart';
import 'package:sukientotapp/data/providers/partner/service_area_provider.dart';
import 'package:sukientotapp/data/repositories/location_repository_impl.dart';
import 'package:sukientotapp/data/repositories/partner/service_area_repository_impl.dart';
import 'package:sukientotapp/domain/repositories/location_repository.dart';
import 'package:sukientotapp/domain/repositories/partner/service_area_repository.dart';

import 'controller.dart';

class PartnerServiceAreasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    Get.lazyPut<LocationProvider>(
      () => LocationProvider(Get.find<ApiService>()),
    );
    Get.lazyPut<LocationRepository>(
      () => LocationRepositoryImpl(Get.find<LocationProvider>()),
    );
    Get.lazyPut<PartnerServiceAreaProvider>(
      () => PartnerServiceAreaProvider(Get.find<ApiService>()),
    );
    Get.lazyPut<PartnerServiceAreaRepository>(
      () => PartnerServiceAreaRepositoryImpl(
        Get.find<PartnerServiceAreaProvider>(),
      ),
    );
    Get.lazyPut<PartnerServiceAreasController>(
      () => PartnerServiceAreasController(
        Get.find<PartnerServiceAreaRepository>(),
        Get.find<LocationRepository>(),
      ),
    );
  }
}
