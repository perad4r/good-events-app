import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sukientotapp/features/components/widget/confirm_dialog.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class UploadPhoto extends StatefulWidget {
  final Function(XFile) onImagePicked;
  final VoidCallback? onImageRemoved;

  const UploadPhoto({
    super.key,
    required this.onImagePicked,
    this.onImageRemoved,
  });

  @override
  State<UploadPhoto> createState() => _UploadPhotoState();
}

class _UploadPhotoState extends State<UploadPhoto> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
      widget.onImagePicked(image);
    }
  }

  void _removeImage() {
    setState(() => _pickedImage = null);
    widget.onImageRemoved?.call();
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      _launchCamera();
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _launchCamera();
      } else if (result.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _launchCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _pickedImage = image);
      widget.onImagePicked(image);
    }
  }

  void _showPermissionDeniedDialog() {
    ConfirmDialog.show(
      title: 'camera_access_required'.tr,
      message: 'camera_permission_denied_desc'.tr,
      confirmText: 'open_settings'.tr,
      cancelText: 'cancel'.tr,
      onConfirm: openAppSettings,
      confirmColor: context.fTheme.colors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFromGallery,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.fTheme.colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.fTheme.colors.border, width: 2),
            ),
            child: _pickedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedImage!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(FIcons.image),
                      Text(
                        'click_to_upload'.tr,
                        style: context.typography.base.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.fTheme.colors.foreground,
                        ),
                      ),
                      Text(
                        'upload_description'.tr,
                        style: context.typography.sm.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        CustomButtonPlus(
          onTap: _pickFromCamera,
          width: double.infinity,
          btnText: 'take_photo'.tr,
          icon: FIcons.camera,
          iconSize: 16,
          textSize: 14,
          fontWeight: FontWeight.w600,
          height: 34,
          borderRadius: 10,
          borderColor: Colors.transparent,
        ),
      ],
    );
  }
}
