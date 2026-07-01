import 'package:sukientotapp/core/utils/import/global.dart';

import '../controller/controller.dart';

class CompletionPhotoSection extends GetView<ClientOrderDetailController> {
  const CompletionPhotoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final imageUrl = controller.completionPhoto?.trim() ?? '';
      if (imageUrl.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF15803D).withValues(alpha: 0.05),
              border: Border.all(
                color: const Color(0xFF15803D).withValues(alpha: 0.4),
                width: 2,
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
                    color: const Color(0xFF15803D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'completion_photo_banner'.tr,
                        style: context.typography.base.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'click_to_view_photo'.tr,
                        style: context.typography.xs.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Hero(
                tag: 'completion_photo_$imageUrl',
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
