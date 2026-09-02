import 'package:get/get.dart';
import 'controller.dart';

class CategoryListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryListController>(
      CategoryListController.new,
    );
  }
}
