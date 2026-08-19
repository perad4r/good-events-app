import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/partner_category_model.dart';
import '../controller.dart';

class CategoryIntroCard extends GetView<ClientHomeController> {
  const CategoryIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'popular_services'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FTappable(
                  onPress: () {
                    controller.ensurePartnersLoaded();
                    controller.openCategoryListBottomSheet(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'view_all'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoadingPartners.value && controller.partnerList.isEmpty) {
                return const SizedBox(
                  height: 230,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final categories = controller.partnerList;

              if (categories.isEmpty) {
                return const SizedBox.shrink();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double itemWidth = (constraints.maxWidth - 24) / 3.5;

                  return SizedBox(
                    height: 230,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: itemWidth,
                      ),
                      itemBuilder: (context, index) {
                        final PartnerCategoryModel category = categories[index];
                        return _CategoryItem(
                          category: category,
                          onTap: () => controller.openCategoryListBottomSheet(
                            context,
                            selectedCategory: category,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ],
        ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, required this.onTap});

  final PartnerCategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
                imageUrl: category.image,
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
                  category.name,
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