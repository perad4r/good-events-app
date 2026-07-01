import 'package:sukientotapp/core/utils/import/global.dart';
import 'controller/controller.dart';
import 'widgets/order_detail_header.dart';
import 'widgets/partner_section.dart';
import 'widgets/booking_photos_section.dart';
import 'widgets/arrival_photo_section.dart';
import 'widgets/completion_photo_section.dart';
import 'widgets/user_review_section.dart';
import 'widgets/detailed_info_section.dart';
import 'widgets/bottom_actions.dart';

class ClientOrderDetailScreen extends GetView<ClientOrderDetailController> {
  const ClientOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            titleSpacing: 0,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'back_to_list'.tr,
              style: context.typography.sm.copyWith(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            child: SmartRefresher(
              controller: controller.refreshController,
              onRefresh: controller.onRefresh,
              enablePullUp: false,
              header: const ClassicHeader(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OrderDetailHeader(),
                    const SizedBox(height: 16),
                    const PartnerSection(),
                    const SizedBox(height: 16),
                    const BookingPhotosSection(),
                    const ArrivalPhotoSection(),
                    const CompletionPhotoSection(),
                    const SizedBox(height: 18),
                    const UserReviewSection(),
                    const SizedBox(height: 18),
                    const DetailedInfoSection(),
                    const SizedBox(height: 100), // Bottom padding for fixed buttons
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const BottomActions(),
        ),
        Obx(() {
          if (controller.isChoosingPartner.value || controller.isCancellingOrder.value) {
            return Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
