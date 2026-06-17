import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';
import 'applicant_card.dart';

class PartnerSection extends GetView<ClientOrderDetailController> {
  const PartnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: FTheme.of(context).colors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (!controller.isHistory.value && controller.status != 'pending') {
              return const SizedBox.shrink();
            }
            return Text(
              controller.isHistory.value
                  ? 'you_are_viewing_history'.tr
                  : 'please_wait_a_moment'.tr,
              style: context.typography.sm.copyWith(color: Colors.grey[600]),
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            // Current orders: loop over applicants from the API
            if (!controller.isHistory.value) {
              if (controller.isLoadingDetails.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allItems = controller.orderDetail.value?.items ?? [];
              if (allItems.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'partner_not_found'.tr,
                      style: context.typography.sm.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              // If a partner was already chosen (closed), only show that one
              final closedItem = allItems
                  .where((i) => i.status == 'closed')
                  .toList();
              final items = closedItem.isNotEmpty ? closedItem : allItems;

              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ApplicantCard(item: item),
                      ),
                    )
                    .toList(),
              );
            }

            // History orders: show the single chosen partner from controller
            return _buildHistoryPartnerCard(context);
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryPartnerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: FTheme.of(context).colors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(
                    color: FTheme.of(
                      context,
                    ).colors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(controller.partnerName)}&background=random&size=512&format=png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.partnerName,
                      style: context.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.partnerRating ?? 5} ',
                          style: context.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '(1 ${'rate'.tr})',
                          style: context.typography.sm.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'proposed_partner_price'.tr,
                      style: context.typography.xs.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(controller.finalTotal)} đ',
                      style: context.typography.base.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FTheme.of(context).colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Obx(() {
            if (!controller.canViewPartnerProfile) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final partnerId = controller.partnerId;
                        if (partnerId != null) {
                          controller.openPartnerProfilePreview(partnerId);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FTheme.of(context).colors.primary,
                        side: BorderSide(
                          color: FTheme.of(context).colors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('profile'.tr),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
