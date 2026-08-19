import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';
import '../controller.dart';

class PopupPartnerSearchSheet extends StatefulWidget {
  const PopupPartnerSearchSheet({
    super.key,
    required this.partnerCategories,
    required this.isLoadingPartners,
    this.selectedCategory,
  });

  final RxList<PartnerCategoryModel> partnerCategories;
  final RxBool isLoadingPartners;
  final PartnerCategoryModel? selectedCategory;

  @override
  State<PopupPartnerSearchSheet> createState() =>
      _PopupPartnerSearchSheetState();
}

class _PopupPartnerSearchSheetState extends State<PopupPartnerSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  String _removeDiacritics(String str) {
    const withDiacritics =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    var lowerStr = str.toLowerCase();
    for (int i = 0; i < withDiacritics.length; i++) {
      lowerStr = lowerStr.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return lowerStr;
  }

  List<PartnerCategoryModel> get _filteredCategories {
    final query = _removeDiacritics(_searchQuery.value.trim());
    final List<PartnerCategoryModel> categories = widget.selectedCategory == null
        ? widget.partnerCategories
        : <PartnerCategoryModel>[widget.selectedCategory!];

    if (query.isEmpty) return categories;

    return categories
        .map((category) {
          final filteredPartners = category.partnerList.where((partner) {
            return _removeDiacritics(partner.name).contains(query);
          }).toList();

          if (filteredPartners.isNotEmpty) {
            return PartnerCategoryModel(
              id: category.id,
              name: category.name,
              image: category.image,
              partnerList: filteredPartners,
            );
          }
          return null;
        })
        .whereType<PartnerCategoryModel>()
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.only(top: 45),
          height: Get.height,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  FTappable(
                    onPress: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                      child: Icon(FIcons.chevronDown),
                    ),
                  ),
                  Text(
                    widget.selectedCategory?.name ?? 'partner_search'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'search_with_dot'.tr,
                  onChanged: (value) {
                    _searchQuery.value = value;
                  },
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.search),
                  ),
                  trailing: [
                    Obx(
                      () => _searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (widget.isLoadingPartners.value &&
                      widget.partnerCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text('loading_with_dot'.tr),
                        ],
                      ),
                    );
                  }

                  final filtered = _filteredCategories;

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.value.isEmpty
                            ? 'in_dev'.tr
                            : 'no_results_found'.tr,
                        style: TextStyle(
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      for (int i = 0; i < filtered.length; i++) ...[
                        SliverToBoxAdapter(
                          child: _buildCategoryHeader(filtered[i]),
                        ),
                        _buildPartnerSliverGrid(filtered[i]),
                        if (i < filtered.length - 1)
                          const SliverToBoxAdapter(
                            child: Divider(
                              height: 5.0,
                              thickness: 5.0,
                              color: Color.fromARGB(32, 140, 126, 126),
                            ),
                          ),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 100.ms)
        .slideY(duration: 560.ms, begin: 0.1, end: 0, curve: Curves.elasticOut);
  }

  /// build category header
  Widget _buildCategoryHeader(PartnerCategoryModel category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category.name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// build partner sliver grid
  Widget _buildPartnerSliverGrid(PartnerCategoryModel category) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return PartnerItem(partner: category.partnerList[index]);
      }, childCount: category.partnerList.length),
    );
  }
}

class PartnerItem extends StatelessWidget {
  const PartnerItem({super.key, required this.partner});

  final PartnerSubcategoryModel partner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.back();
        final controller = Get.find<ClientHomeController>();
        controller.openDetailScreen(partner.slug);
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: partner.image,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 70,
                  width: 70,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 70,
                  width: 70,
                  child: Center(child: Icon(Icons.error, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  textAlign: TextAlign.center,
                  partner.name,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
