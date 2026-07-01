import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';

class BookingPhotosSection extends GetView<ClientOrderDetailController> {
  const BookingPhotosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<String> photos = controller.bookingPhotos;
      if (photos.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.red600.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.red600.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.red600.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FIcons.image,
                      color: AppColors.red600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'booking_photos_title'.tr,
                          style: context.typography.base.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'booking_photos_subtitle'.trParams({
                            'count': photos.length.toString(),
                          }),
                          style: context.typography.xs.copyWith(
                            color: context.fTheme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int index = 0;
                      index < photos.length && index < 5;
                      index++)
                    _BookingPhotoTile(
                      imageUrl: photos[index],
                      index: index,
                      onTap: () => _showFullScreenImage(context, photos[index]),
                    ),
                ],
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
        onTap: () => Get.back(),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Hero(
                tag: 'booking_photo_$imageUrl',
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

class _BookingPhotoTile extends StatelessWidget {
  const _BookingPhotoTile({
    required this.imageUrl,
    required this.index,
    required this.onTap,
  });

  final String imageUrl;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'booking_photo_$imageUrl',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 86,
                  height: 86,
                  color: AppColors.red600.withValues(alpha: 0.06),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 86,
                  height: 86,
                  color: Colors.grey[100],
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: context.typography.xs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
