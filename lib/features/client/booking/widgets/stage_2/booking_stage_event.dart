import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import 'package:sukientotapp/features/components/button/plus.dart';
import '../booking_fields.dart';
import '../booking_header.dart';
import '../booking_option_sheet.dart';

class BookingEventStage extends GetView<ClientBookingController> {
  const BookingEventStage({super.key});

  static final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingHeader(
          icon: FIcons.notebookText,
          title: 'booking_stage_event_title'.tr,
          subtitle: 'booking_stage_event_subtitle'.tr,
        ),
        const SizedBox(height: 24),
        Obx(
          () => BookingSelectField(
            label: 'booking_event_type'.tr,
            value: controller.selectedEventType.value.isEmpty
                ? ''
                : controller.selectedEventType.value.tr,
            placeholder: 'booking_event_type_placeholder'.tr,
            errorText: controller.fieldErrors['eventType'],
            onTap: () => _showOptions(
              title: 'booking_event_type'.tr,
              options: controller.eventTypes,
              selectedValue: controller.selectedEventType.value,
              onSelect: controller.selectEventType,
              labelBuilder: (value) => value.tr,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => controller.shouldShowCustomEvent
              ? BookingTextField(
                  label: 'booking_event_custom'.tr,
                  hint: 'booking_event_custom_placeholder'.tr,
                  controller: controller.customEventController,
                  errorText: controller.fieldErrors['customEvent'],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        BookingTextField(
          label: 'booking_note_optional'.tr,
          hint: 'booking_note_placeholder'.tr,
          controller: controller.noteController,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Obx(() {
          final List<XFile> photos = controller.bookingPhotos.toList();
          final String? errorText = controller.fieldErrors['bookingPhoto'];

          return _BookingPhotoField(
            photos: photos,
            errorText: errorText,
            maxPhotos: ClientBookingController.maxBookingPhotos,
            onPickGallery: _pickPhotosFromGallery,
            onPickCamera: () => _pickPhoto(ImageSource.camera),
            onRemoveAt: controller.removeBookingPhotoAt,
          );
        }),
      ],
    );
  }

  Future<void> _pickPhotosFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      await controller.addBookingPhotos(images);
    } catch (e) {
      logger.e('[BookingEventStage] Failed to pick images: $e');
      Get.snackbar('error'.tr, 'booking_stage_photo_cannot_select'.tr);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      await controller.addBookingPhoto(image);
    } catch (e) {
      logger.e('[BookingEventStage] Failed to pick image: $e');
      Get.snackbar('error'.tr, 'booking_stage_photo_cannot_select'.tr);
    }
  }

  void _showOptions<T>({
    required String title,
    required List<T> options,
    required T? selectedValue,
    required ValueChanged<T> onSelect,
    String Function(T value)? labelBuilder,
  }) {
    if (options.isEmpty) return;
    Get.bottomSheet(
      BookingOptionSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
        onSelect: onSelect,
        labelBuilder: labelBuilder,
      ),
      isScrollControlled: true,
    );
  }
}

class _BookingPhotoField extends StatelessWidget {
  const _BookingPhotoField({
    required this.photos,
    required this.errorText,
    required this.maxPhotos,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemoveAt,
  });

  final List<XFile> photos;
  final String? errorText;
  final int maxPhotos;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    final bool hasPhotos = photos.isNotEmpty;
    final bool canAddMore = photos.length < maxPhotos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText == null
              ? AppColors.red600.withValues(alpha: 0.14)
              : AppColors.red600,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoIconBadge(photoCount: photos.length, maxPhotos: maxPhotos),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'booking_stage_photo_title'.tr,
                      style: context.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'booking_stage_photo_empty_subtitle'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.sm.copyWith(
                        color: context.fTheme.colors.mutedForeground,
                      ),
                    ),
                    if (hasPhotos) ...[
                      const SizedBox(height: 4),
                      Text(
                        'booking_stage_photo_selected_count'.trParams({
                          'count': photos.length.toString(),
                          'max': maxPhotos.toString(),
                        }),
                        style: context.typography.xs.copyWith(
                          color: context.fTheme.colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasPhotos) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int index = 0; index < photos.length; index++)
                  _PhotoThumbnail(
                    photo: photos[index],
                    onRemove: () => onRemoveAt(index),
                  ),
              ],
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: context.typography.sm.copyWith(color: AppColors.red600),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomButtonPlus(
                  onTap: onPickGallery,
                  btnText: canAddMore
                      ? 'choose_picture'.tr
                      : 'booking_stage_photo_full'.tr,
                  icon: FIcons.image,
                  iconSize: 14,
                  textSize: 13,
                  height: 36,
                  borderRadius: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red600,
                  textColor: Colors.white,
                  borderColor: Colors.transparent,
                  isDisabled: !canAddMore,
                  shrinkText: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButtonPlus(
                  onTap: onPickCamera,
                  btnText: 'take_photo'.tr,
                  icon: FIcons.camera,
                  iconSize: 14,
                  textSize: 13,
                  height: 36,
                  borderRadius: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red600,
                  textColor: Colors.white,
                  borderColor: Colors.transparent,
                  isDisabled: !canAddMore,
                  shrinkText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'booking_stage_photo_subtitle_2'.tr,
            textAlign: TextAlign.center,
            style: context.typography.xs.copyWith(
              color: context.fTheme.colors.mutedForeground,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoIconBadge extends StatelessWidget {
  const _PhotoIconBadge({required this.photoCount, required this.maxPhotos});

  final int photoCount;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.red600.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red600.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FIcons.imagePlus,
            size: 18,
            color: AppColors.red600,
          ),
          const SizedBox(height: 1),
          Text(
            '$photoCount/$maxPhotos',
            style: context.typography.xs.copyWith(
              color: AppColors.red600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.file(
            File(photo.path),
            width: 68,
            height: 68,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
