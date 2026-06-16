import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/service_model.dart';
import '../controller.dart';

class ManageServiceMediaSheet extends GetView<MyServicesController> {
  const ManageServiceMediaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.fTheme.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.fTheme.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'manage_service_images'.tr,
                            style: context.typography.xl.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Obx(
                            () => Text(
                              '${'images_count'.tr}: ${controller.serviceImages.length}/10',
                              style: context.typography.sm.copyWith(
                                color: context.fTheme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.fTheme.colors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          FIcons.x,
                          size: 18,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.fTheme.colors.border),

              // Body
              Expanded(
                child: Obx(() {
                  if (controller.isMediaLoading.value) {
                    return const _MediaSheetSkeleton();
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    children: [
                      // Section label
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: context.fTheme.colors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              FIcons.image,
                              size: 12,
                              color: context.fTheme.colors.primaryForeground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                                'service_images'.tr,
                                style: context.typography.base.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: -0.02,
                                end: 0,
                                curve: Curves.easeOut,
                              ),
                          const Spacer(),
                          Obx(() {
                            final count = controller.serviceImages.length;
                            return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: count >= 10
                                        ? context.fTheme.colors.destructive
                                              .withValues(alpha: 0.1)
                                        : context.fTheme.colors.primary
                                              .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$count/10',
                                    style: context.typography.xs.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: count >= 10
                                          ? context.fTheme.colors.destructive
                                          : context.fTheme.colors.primary,
                                    ),
                                  ),
                                )
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                  begin: -0.02,
                                  end: 0,
                                  curve: Curves.easeOut,
                                );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image grid or empty state
                      if (controller.serviceImages.isEmpty)
                        _ImagesEmptyState()
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.serviceImages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final img = controller.serviceImages[index];
                            return _ImageTile(image: img)
                                .animate(delay: (200 + index * 100).ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                  begin: -0.02,
                                  end: 0,
                                  curve: Curves.easeOut,
                                );
                          },
                        ),

                      const SizedBox(height: 24),

                      // Add images button
                      Obx(() {
                        final atLimit = controller.serviceImages.length >= 10;
                        final uploading = controller.isUploadingImages.value;
                        return FButton(
                              onPress: (atLimit || uploading)
                                  ? null
                                  : controller.pickAndUploadImages,
                              style: FButtonStyle.outline(),
                              child: uploading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                context.fTheme.colors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('uploading_images'.tr),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          FIcons.imagePlus,
                                          size: 16,
                                          color: atLimit
                                              ? context
                                                    .fTheme
                                                    .colors
                                                    .mutedForeground
                                              : context.fTheme.colors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          atLimit
                                              ? 'images_limit_reached'.tr
                                              : 'add_images'.tr,
                                        ),
                                      ],
                                    ),
                            )
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(
                              begin: -0.02,
                              end: 0,
                              curve: Curves.easeOut,
                            );
                      }),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

class _MediaSheetSkeleton extends StatelessWidget {
  const _MediaSheetSkeleton();

  Widget _box(
    BuildContext context, {
    double height = 16,
    double? width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.fTheme.colors.secondary,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(context, height: 13, width: 110),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, _) => Container(
              decoration: BoxDecoration(
                color: context.fTheme.colors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Images Empty State ───────────────────────────────────────────────────────

class _ImagesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: BoxDecoration(
            color: context.fTheme.colors.secondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fTheme.colors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.fTheme.colors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.fTheme.colors.border),
                ),
                child: Icon(
                  FIcons.image,
                  size: 26,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'no_images_yet'.tr,
                style: context.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.fTheme.colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'tap_add_images_hint'.tr,
                textAlign: TextAlign.center,
                style: context.typography.xs.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.02, end: 0, curve: Curves.easeOut);
  }
}

class _ImageTile extends GetView<MyServicesController> {
  final ServiceImageModel image;

  const _ImageTile({required this.image});

  @override
  Widget build(BuildContext context) {
    final previewUrl = image.previewUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: previewUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: context.fTheme.colors.secondary,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: context.fTheme.colors.secondary,
                    child: Icon(
                      FIcons.imageOff,
                      color: context.fTheme.colors.mutedForeground,
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: context.fTheme.colors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FIcons.image,
                    color: context.fTheme.colors.mutedForeground,
                  ),
                ),
        ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                image.fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),

        // Delete button
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.fTheme.colors.background,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.fTheme.colors.destructive.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FIcons.trash2,
                  size: 20,
                  color: context.fTheme.colors.destructive,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'delete_image_confirm_title'.tr,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_image_confirm_desc'.tr,
                style: context.typography.sm.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: () => Get.back(),
                      style: FButtonStyle.outline(),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FButton(
                      onPress: () {
                        Get.back();
                        controller.deleteServiceImage(image.id);
                      },
                      style: FButtonStyle.destructive(),
                      child: Text('delete'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
