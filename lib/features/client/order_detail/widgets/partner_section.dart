import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';
import 'applicant_card.dart';

class PartnerSection extends GetView<ClientOrderDetailController> {
  const PartnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = FTheme.of(context).colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (!controller.isHistory.value) {
              return _buildNoticeBanner(context);
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'you_are_viewing_history'.tr,
                style: context.typography.sm.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
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
                return _buildWaitingQuoteState(context);
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

  Widget _buildWaitingQuoteState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Color(0xFF64748B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Đang chờ nhân sự báo giá',
              style: context.typography.sm.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner(BuildContext context) {
    String noticeText = 'time_warning'.tr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD97706),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noticeText,
              style: context.typography.sm.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPartnerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: FTheme.of(context).colors.primary.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(12),
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
                    controller.partnerAvatarUrl,
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
                          '(${controller.partnerTotalRatings?.toInt() ?? 0} ${'rate'.tr})',
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
