import 'package:get/get.dart';
import 'controller.dart';

import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/providers/partner/new_show_provider.dart';
import 'package:sukientotapp/domain/repositories/partner/new_show_repository.dart';
import 'package:sukientotapp/data/repositories/partner/new_show_repository_impl.dart';

class NewShowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);

    Get.lazyPut<NewShowProvider>(
      () => NewShowProvider(Get.find<ApiService>()),
    );

    Get.lazyPut<NewShowRepository>(
      () => NewShowRepositoryImpl(Get.find<NewShowProvider>()),
    );

    Get.put<NewShowController>(
      NewShowController(Get.find<NewShowRepository>()),
      permanent: true,
    );
  }
}
