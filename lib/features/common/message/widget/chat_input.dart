import 'dart:io';

import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller.dart';

class ChatInput extends StatelessWidget {
  final MessageController controller;

  const ChatInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // File attachment preview row
          Obx(() {
            if (controller.selectedImages.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.selectedImages.length,
                itemBuilder: (context, index) {
                  final image = controller.selectedImages[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => controller.removeSelectedImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
          Obx(() {
            if (controller.selectedImages.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  Text(
                    '${controller.selectedImages.length}/20 ảnh đã chọn',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.clearSelectedImages,
                    child: Text(
                      'Xóa tất cả',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            if (!controller.isSendingMessage.value) {
              return const SizedBox.shrink();
            }
            return LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            );
          }),
          // Input row
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AttachmentButton(controller: controller),
                  const SizedBox(width: 8),
                  // Text input (pill shape)
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: controller.messageController,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'type_a_message'.tr,
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Obx(() {
                    final isSending = controller.isSendingMessage.value;
                    return GestureDetector(
                      onTap: isSending ? null : controller.sendMessage,
                      child: AnimatedOpacity(
                        opacity: isSending ? 0.65 : 1,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentButton extends StatefulWidget {
  const _AttachmentButton({required this.controller});

  final MessageController controller;

  @override
  State<_AttachmentButton> createState() => _AttachmentButtonState();
}

class _AttachmentButtonState extends State<_AttachmentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  OverlayEntry? _overlayEntry;

  static const double _menuWidth = 164;
  static const double _menuHeight = 106;
  static const double _menuGap = 2;
  static const double _arrowSize = 12;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 130),
    );
    final curved = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = curved;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 24,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _toggleMenu() async {
    if (_overlayEntry != null) {
      await _hideMenu();
      return;
    }

    _showMenu();
  }

  void _showMenu() {
    final overlayState = Overlay.of(context);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final buttonBox = context.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final left = buttonPosition.dx
        .clamp(12.0, overlayBox.size.width - _menuWidth - 12.0)
        .toDouble();
    final buttonCenterX = buttonPosition.dx + (buttonBox.size.width / 2);
    final arrowCenterX = (buttonCenterX - left)
        .clamp(_arrowSize + 8, _menuWidth - _arrowSize - 8)
        .toDouble();
    final top = (buttonPosition.dy - _menuHeight - _menuGap)
        .clamp(8.0, overlayBox.size.height - _menuHeight - 8.0)
        .toDouble();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideMenu,
                child: const SizedBox.expand(),
              ),
              Positioned(
                left: left,
                top: top,
                width: _menuWidth,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _AttachmentMenuPanel(
                      arrowCenterX: arrowCenterX,
                      onImageTap: () async {
                        await _hideMenu();
                        await widget.controller.pickImagesForMessage();
                      },
                      onLocationTap: () async {
                        await _hideMenu();
                        await widget.controller.sendCurrentLocation();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    _animationController.forward(from: 0);
  }

  Future<void> _hideMenu() async {
    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _AttachmentMenuPanel extends StatelessWidget {
  const _AttachmentMenuPanel({
    required this.arrowCenterX,
    required this.onImageTap,
    required this.onLocationTap,
  });

  final double arrowCenterX;
  final VoidCallback onImageTap;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachmentMenuItem(
                icon: Icons.image_outlined,
                label: 'Chọn ảnh',
                onTap: onImageTap,
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _AttachmentMenuItem(
                icon: Icons.location_on_outlined,
                label: 'Gửi vị trí',
                onTap: onLocationTap,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: arrowCenterX - 9),
          child: CustomPaint(
            size: const Size(18, 10),
            painter: _PopoverArrowPainter(),
          ),
        ),
      ],
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AttachmentMenuItem extends StatelessWidget {
  const _AttachmentMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
