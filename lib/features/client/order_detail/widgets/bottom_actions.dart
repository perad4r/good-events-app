import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/common/message/detail_screen.dart';
import '../controller/controller.dart';

class BottomActions extends GetView<ClientOrderDetailController> {
  const BottomActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.status;
      final isEnded = status == 'completed' || status == 'cancelled' || status == 'expired';

      // If it's a history item or the status is ended, we handle history-like actions
      if (controller.isHistory.value || isEnded) {
        if (controller.canSubmitReview) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showReviewBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FTheme.of(context).colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('rate_now'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }

        // If it's cancelled or expired, we don't show any bottom actions
        return const SizedBox.shrink();
      }

      // Otherwise, (current orders tab and active status) show Chat and Cancel Buttons
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.canChat
                      ? () async {
                          if (!Get.isRegistered<MessageController>()) {
                            Get.snackbar('error'.tr, 'error'.tr);
                            return;
                          }

                          final messageController = Get.find<MessageController>();
                          var thread = messageController.filteredMessages.firstWhereOrNull(
                            (t) => t.bill.id == controller.orderId,
                          );

                          if (thread == null) {
                            await messageController.refreshThreads();
                            thread = messageController.filteredMessages.firstWhereOrNull(
                              (t) => t.bill.id == controller.orderId,
                            );
                          }

                          if (thread == null) {
                            Get.snackbar('error'.tr, 'thread_not_found'.tr);
                            return;
                          }

                          await messageController.openThread(thread);
                          await Get.to<void>(() => const MessageDetailScreen());
                          messageController.closeThread();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FTheme.of(context).colors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('chat_now'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.cancelOrder(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'cancel_order'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showReviewBottomSheet(BuildContext context) {
    // Reset state before showing
    controller.rating.value = 0;
    controller.reviewCommentController.clear();

    Get.bottomSheet(
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'rate_order'.tr,
                      style: context.typography.lg.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'rate_partner'.tr,
                      style: context.typography.sm.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Row(
                        children: List.generate(5, (index) {
                          final isSelected = index < controller.rating.value;
                          return IconButton(
                            icon: Icon(
                              isSelected ? Icons.star : Icons.star_outline,
                              color: isSelected ? Colors.amber : Colors.grey,
                              size: 32,
                            ),
                            splashRadius: 24,
                            onPressed: () {
                              controller.rating.value = index + 1;
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'review_service'.tr,
                      style: context.typography.sm.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.reviewCommentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'share_experience'.tr,
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      final canSubmit =
                          controller.rating.value > 0 && !controller.isSubmittingReview.value;
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: canSubmit
                                  ? () {
                                      final pId = controller.partnerId;
                                      if (pId != null) {
                                        controller.submitReview(pId);
                                      } else {
                                        Get.snackbar('error'.tr, 'partner_not_found'.tr);
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FTheme.of(context).colors.primary,
                                disabledBackgroundColor: Colors.grey[300],
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: controller.isSubmittingReview.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'submit_review'.tr,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
