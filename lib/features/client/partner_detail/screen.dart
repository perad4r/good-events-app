import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/common/language_switch/language_switch.dart';
import 'controller.dart';
import 'widgets/header_image.dart';
import 'widgets/info_card.dart';
import 'widgets/description.dart';
import 'widgets/attributes.dart';
import 'widgets/action_buttons.dart';

class PartnerDetailScreen extends GetView<PartnerDetailController> {
  const PartnerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: Obx(
          () => Text(
            controller.partnerName.value.isEmpty
                ? 'Partner Details'
                : controller.partnerName.value,
          ),
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Get.back<void>(),
          ),
        ],
        suffixes: [LanguageSwitch()],
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text('loading_with_dot'.tr),
              ],
            ),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image
                  PartnerHeaderImage(imageUrl: controller.partnerImage.value),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      // 2. Info Card
                      PartnerInfoCard(controller: controller),
                      const SizedBox(height: 24),

                      // 3. Content (Video & Description)
                      PartnerContentWidget(controller: controller),
                      const SizedBox(height: 24),

                      // 4. Attributes
                      PartnerAttributesWidget(controller: controller),

                      // Bottom padding
                      const SizedBox(height: 50),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PartnerActionButtons(),
            ),
          ],
        );
      }),
    );
  }
}
