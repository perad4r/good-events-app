import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/booking/controller.dart';
import 'booking_stage_navigation.dart';
import 'stage_content.dart';

class BookingForm extends GetView<ClientBookingController> {
  const BookingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      final bool shouldLiftNavigation =
          defaultTargetPlatform == TargetPlatform.iOS && keyboardInset > 0;
      final double navigationBottom = shouldLiftNavigation ? keyboardInset : 0;
      final double scrollBottomPadding = shouldLiftNavigation
          ? keyboardInset + 140
          : 140;

      return Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, scrollBottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookingStageContent(stage: controller.currentStage.value),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: navigationBottom,
            child: BookingStageNavigation(
              isFirstStage: controller.isFirstStage,
              isLastStage: controller.isLastStage,
              isSubmitting: controller.isSubmitting.value,
              onBack: () => Get.back(),
              onPrevious: controller.previousStage,
              onNext: controller.nextStage,
              onSubmit: controller.submitBooking,
            ),
          ),
        ],
      );
    });
  }
}
