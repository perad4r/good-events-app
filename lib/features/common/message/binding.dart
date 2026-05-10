import 'package:get/get.dart';
import 'controller.dart';

import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/providers/common/report_provider.dart';
import 'package:sukientotapp/domain/api_url.dart';
import 'package:sukientotapp/domain/repositories/common/report_repository.dart';
import 'package:sukientotapp/domain/repositories/partner/message_repository.dart';
import 'package:sukientotapp/data/repositories/common/report_repository_impl.dart';
import 'package:sukientotapp/data/repositories/partner/message_repository_impl.dart';
import 'package:sukientotapp/data/providers/common/message_provider.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);

    Get.lazyPut<MessageProvider>(() => MessageProvider(Get.find<ApiService>()), fenix: true);
    Get.lazyPut<ReportProvider>(
      () => ReportProvider(dio: Get.find<ApiService>().dio),
      fenix: true,
    );
    Get.lazyPut<ReportRepository>(
      () => ReportRepositoryImpl(Get.find<ReportProvider>()),
      fenix: true,
    );
    final endpoint = AppUrl.chats;

    Get.lazyPut<MessageRepository>(
      () => MessageRepositoryImpl(
        Get.find<MessageProvider>(),
        endpoint: endpoint,
      ),
      fenix: true,
    );

    Get.lazyPut<MessageController>(
      () => MessageController(Get.find<MessageRepository>()),
      fenix: true,
    );
  }
}
