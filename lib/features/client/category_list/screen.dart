import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';

import 'controller.dart';

class CategoryListScreen extends GetView<CategoryListController> {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          controller.selectedCategory?.name ?? 'partner_search'.tr,
        ),
        prefixes: [FHeaderAction.back(onPress: () => Get.back<void>())],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: controller.searchController,
              hintText: 'search_with_dot'.tr,
              onChanged: controller.updateSearchQuery,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.search),
              ),
              trailing: [
                Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.categories.isEmpty) {
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

      final List<PartnerCategoryModel> filtered =
          controller.filteredCategories;
      if (filtered.isEmpty) {
        return Center(
          child: Text(
            controller.searchQuery.value.isEmpty
                ? 'in_dev'.tr
                : 'no_results_found'.tr,
            style: TextStyle(color: context.fTheme.colors.mutedForeground),
          ),
        );
      }

      return CustomScrollView(
        slivers: [
          for (int index = 0; index < filtered.length; index++) ...[
            SliverToBoxAdapter(child: _CategoryHeader(filtered[index])),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: _PartnerGrid(
                category: filtered[index],
                onPartnerTap: controller.openPartnerDetail,
              ),
            ),
            if (index < filtered.length - 1)
              const SliverToBoxAdapter(
                child: Divider(
                  height: 5,
                  thickness: 5,
                  color: Color.fromARGB(32, 140, 126, 126),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    });
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(this.category);

  final PartnerCategoryModel category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        category.name,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PartnerGrid extends StatelessWidget {
  const _PartnerGrid({required this.category, required this.onPartnerTap});

  final PartnerCategoryModel category;
  final ValueChanged<String> onPartnerTap;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final PartnerSubcategoryModel partner = category.partnerList[index];
          return _PartnerItem(
            partner: partner,
            onTap: () => onPartnerTap(partner.slug),
          );
        },
        childCount: category.partnerList.length,
      ),
    );
  }
}

class _PartnerItem extends StatelessWidget {
  const _PartnerItem({required this.partner, required this.onTap});

  final PartnerSubcategoryModel partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: partner.image,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String url) =>
                  const SizedBox(
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
              errorWidget:
                  (BuildContext context, String url, Object error) =>
                      const SizedBox(
                        height: 70,
                        width: 70,
                        child: Center(
                          child: Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                partner.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
