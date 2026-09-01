import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';

class ArrivalPhotoSection extends GetView<ClientOrderDetailController> {
  const ArrivalPhotoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String? imageUrl = controller.arrivalPhoto;
      final String createTime = controller.arrivalPhotoCreateTime?.trim() ?? '';

      // If not history AND no specific arrival photo, hide the section
      if (!controller.isHistory.value && (imageUrl == null || imageUrl.isEmpty)) {
        return const SizedBox.shrink();
      }

      // As requested, if arrival_photo is null, use category_image
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = controller.categoryImage;
      }

      return GestureDetector(
        onTap: () {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            _showFullScreenImage(context, imageUrl);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: FTheme.of(context).colors.primary.withValues(alpha: 0.05),
            border: Border.all(
              color: FTheme.of(context).colors.primary.withValues(alpha: 0.4),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: FTheme.of(context).colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported, color: Colors.grey),
                        )
                      : const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'arrival_photo_banner'.tr,
                      style: context.typography.base.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'click_to_view_photo'.tr,
                      style: context.typography.xs.copyWith(color: Colors.grey[600]),
                    ),
                    if (createTime.isNotEmpty)
                      Text(
                        createTime,
                        style: context.typography.xs.copyWith(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(), // tapping anywhere closes
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Hero(
                tag: imageUrl,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black87,
    );
  }
}
