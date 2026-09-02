import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';
import 'package:sukientotapp/features/client/home/controller.dart';

class CategoryListController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  late final RxList<PartnerCategoryModel> _categories;
  late final RxBool _isLoading;
  PartnerCategoryModel? _selectedCategory;

  RxList<PartnerCategoryModel> get categories => _categories;
  RxBool get isLoading => _isLoading;

  PartnerCategoryModel? get selectedCategory => _selectedCategory;

  List<PartnerCategoryModel> get filteredCategories {
    final String query = _removeDiacritics(searchQuery.value.trim());
    final List<PartnerCategoryModel> source = selectedCategory == null
        ? categories
        : <PartnerCategoryModel>[selectedCategory!];

    if (query.isEmpty) return source;

    return source
        .map((PartnerCategoryModel category) {
          final List<PartnerSubcategoryModel> filteredPartners = category
              .partnerList
              .where(
                (PartnerSubcategoryModel partner) =>
                    _removeDiacritics(partner.name).contains(query),
              )
              .toList();
          if (filteredPartners.isEmpty) return null;
          return PartnerCategoryModel(
            id: category.id,
            name: category.name,
            image: category.image,
            partnerList: filteredPartners,
          );
        })
        .whereType<PartnerCategoryModel>()
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    final Object? arguments = Get.arguments;
    if (arguments is Map<String, dynamic> &&
        arguments['categories'] is RxList<PartnerCategoryModel> &&
        arguments['isLoading'] is RxBool) {
      _categories = arguments['categories'] as RxList<PartnerCategoryModel>;
      _isLoading = arguments['isLoading'] as RxBool;
      final Object? category = arguments['selectedCategory'];
      if (category is PartnerCategoryModel) _selectedCategory = category;
      return;
    }

    final ClientHomeController homeController =
        Get.find<ClientHomeController>();
    _categories = homeController.partnerList;
    _isLoading = homeController.isLoadingPartners;
    homeController.ensurePartnersLoaded();

    if (arguments is Map<String, dynamic>) {
      final Object? category = arguments['selectedCategory'];
      if (category is PartnerCategoryModel) _selectedCategory = category;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void updateSearchQuery(String value) => searchQuery.value = value;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  Future<void> openPartnerDetail(String slug) async {
    await Get.toNamed(
      Routes.partnerDetail,
      arguments: <String, String>{'slug': slug},
    );
  }

  String _removeDiacritics(String value) {
    const String withDiacritics =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const String withoutDiacritics =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    String normalized = value.toLowerCase();
    for (int index = 0; index < withDiacritics.length; index++) {
      normalized = normalized.replaceAll(
        withDiacritics[index],
        withoutDiacritics[index],
      );
    }
    return normalized;
  }
}
