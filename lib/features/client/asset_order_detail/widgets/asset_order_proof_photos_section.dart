import 'package:sukientotapp/core/utils/import/global.dart';

import '../controller.dart';

class AssetOrderProofPhotosSection
    extends GetView<ClientAssetOrderDetailController> {
  const AssetOrderProofPhotosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final arrivalPhoto = controller.arrivalPhoto?.trim() ?? '';
    final completionPhoto = controller.completionPhoto?.trim() ?? '';

    if (arrivalPhoto.isEmpty && completionPhoto.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          if (arrivalPhoto.isNotEmpty)
            _ProofPhotoTile(
              imageUrl: arrivalPhoto,
              title: 'arrival_photo_banner'.tr,
              accentColor: FTheme.of(context).colors.primary,
            ),
          if (arrivalPhoto.isNotEmpty && completionPhoto.isNotEmpty)
            const SizedBox(height: 10),
          if (completionPhoto.isNotEmpty)
            _ProofPhotoTile(
              imageUrl: completionPhoto,
              title: 'completion_photo_banner'.tr,
              accentColor: const Color(0xFF15803D),
            ),
        ],
      ),
    );
  }
}

class _ProofPhotoTile extends StatelessWidget {
  const _ProofPhotoTile({
    required this.imageUrl,
    required this.title,
    required this.accentColor,
  });

  final String imageUrl;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
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
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
    );
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
                tag: 'asset_order_proof_photo_$imageUrl',
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
