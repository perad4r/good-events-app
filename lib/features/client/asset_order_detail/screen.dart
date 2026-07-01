import 'package:sukientotapp/core/utils/import/global.dart';
import 'controller.dart';
import 'widgets/asset_order_detail_header.dart';
import 'widgets/asset_order_info_section.dart';
import 'widgets/asset_order_bottom_actions.dart';
import 'widgets/asset_order_proof_photos_section.dart';

class ClientAssetOrderDetailScreen extends GetView<ClientAssetOrderDetailController> {
  const ClientAssetOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'asset_order_detail_title'.tr,
          style: context.typography.sm.copyWith(color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AssetOrderDetailHeader(),
            const SizedBox(height: 16),
            const AssetOrderProofPhotosSection(),
            const AssetOrderInfoSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AssetOrderBottomActions(),
    );
  }
}
