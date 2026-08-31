import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/client/home_repository.dart';
import 'package:sukientotapp/data/models/client/blog_home_model.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';

class GuestHomeController extends GetxController {
  final HomeRepository _repository;
  GuestHomeController(this._repository);

  RxBool userType = false.obs; // true: customer, false: service provider

  // Blogs Data
  final RxList<BlogItemModel> blogs = <BlogItemModel>[].obs;
  final isLoadingBlogs = false.obs;

  // Partners Data
  final RxList<PartnerCategoryModel> partnerList = <PartnerCategoryModel>[].obs;
  final isLoadingPartners = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Safely handle arguments
    final args = Get.arguments;
    bool isServiceProvider = false;
    if (args != null && args is Map && args.containsKey('isServiceProvider')) {
      isServiceProvider = args['isServiceProvider'] ?? false;
    }

    userType.value = !isServiceProvider;
    fetchBlogs();
    fetchPartners();
  }

  Future<void> fetchBlogs() async {
    if (isLoadingBlogs.value) return;
    isLoadingBlogs.value = true;
    try {
      final res = await _repository.getHomeBlogs();
      blogs.assignAll(res);
    } catch (e) {
      logger.e('Failed to fetch home blogs for guest: $e');
    } finally {
      isLoadingBlogs.value = false;
    }
  }

  Future<void> fetchPartners({bool force = false}) async {
    if (isLoadingPartners.value) return;
    if (!force && partnerList.isNotEmpty) return;

    isLoadingPartners.value = true;
    try {
      final res = await _repository.getPartnerCategories();
      partnerList.assignAll(res);
    } catch (e) {
      logger.e('Failed to fetch partner categories for guest: $e');
    } finally {
      isLoadingPartners.value = false;
    }
  }

  void ensurePartnersLoaded() {
    if (partnerList.isEmpty && !isLoadingPartners.value) {
      fetchPartners();
    }
  }

  Future<void> openCategoryListScreen({
    PartnerCategoryModel? selectedCategory,
  }) async {
    await Get.toNamed(
      Routes.clientCategoryList,
      arguments: <String, Object>{
        'categories': partnerList,
        'isLoading': isLoadingPartners,
        if (selectedCategory != null) 'selectedCategory': selectedCategory,
      },
    );
  }
}
