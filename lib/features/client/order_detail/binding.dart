import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/providers/common/profile_provider.dart';
import 'package:sukientotapp/data/providers/common/report_provider.dart';
import 'package:sukientotapp/data/providers/client/order_provider.dart';
import 'package:sukientotapp/data/repositories/common/my_profile_repository_impl.dart';
import 'package:sukientotapp/data/repositories/common/report_repository_impl.dart';
import 'package:sukientotapp/data/repositories/client/order_repository_impl.dart';
import 'package:sukientotapp/domain/repositories/common/my_profile_repository.dart';
import 'package:sukientotapp/domain/repositories/common/report_repository.dart';
import 'package:sukientotapp/domain/repositories/client/order_repository.dart';
import 'controller/controller.dart';

class ClientOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    Get.lazyPut<ProfileProvider>(() => ProfileProvider(Get.find<ApiService>()));
    Get.lazyPut<MyProfileRepository>(
      () => MyProfileRepositoryImpl(Get.find<ProfileProvider>()),
    );
    Get.lazyPut<ReportProvider>(
      () => ReportProvider(dio: Get.find<ApiService>().dio),
    );
    Get.lazyPut<ReportRepository>(
      () => ReportRepositoryImpl(Get.find<ReportProvider>()),
    );
    Get.lazyPut<OrderProvider>(
      () => OrderProvider(dio: Get.find<ApiService>().dio),
    );
    Get.lazyPut<OrderRepository>(
      () => OrderRepositoryImpl(Get.find<OrderProvider>()),
    );
    Get.lazyPut<ClientOrderDetailController>(
      () => ClientOrderDetailController(
        Get.find<OrderRepository>(),
        Get.find<MyProfileRepository>(),
      ),
    );
  }
}
