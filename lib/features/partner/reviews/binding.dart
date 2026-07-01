import 'package:get/get.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/providers/partner/partner_reviews_provider.dart';
import 'package:sukientotapp/data/repositories/partner/partner_reviews_repository_impl.dart';
import 'package:sukientotapp/domain/repositories/partner/partner_reviews_repository.dart';
import 'controller.dart';

class PartnerReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    Get.lazyPut<PartnerReviewsProvider>(
      () => PartnerReviewsProvider(Get.find<ApiService>()),
    );
    Get.lazyPut<PartnerReviewsRepository>(
      () => PartnerReviewsRepositoryImpl(Get.find<PartnerReviewsProvider>()),
    );
    Get.lazyPut<PartnerReviewsController>(
      () => PartnerReviewsController(Get.find<PartnerReviewsRepository>()),
    );
  }
}
