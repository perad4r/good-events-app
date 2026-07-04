import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';

import 'order_status_badge.dart';

class DetailedInfoSection extends GetView<ClientOrderDetailController> {
  const DetailedInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = FTheme.of(context).colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildCategoryAvatar(context, primary)),
          const SizedBox(height: 14),
          Obx(
            () => Text(
              controller.isHistory.value
                  ? 'detailed_history_info'.tr
                  : 'detailed_rental_info'.tr,
              style: context.typography.xl.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Obx(
              () => OrderStatusBadge(
                status: controller.status,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                borderRadius: BorderRadius.circular(999),
                upperCaseText: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Text(
              '${controller.parentCategoryName} - ${controller.categoryName}',
              style: context.typography.sm.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.event_available_rounded,
                  label: 'event_date'.tr,
                  value: controller.date,
                  primary: primary,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.access_time_filled_rounded,
                  label: 'time'.tr,
                  value: '${controller.startTime} - ${controller.endTime}',
                  primary: primary,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.location_on_rounded,
                  label: 'location'.tr,
                  value: controller.address,
                  primary: primary,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.celebration_rounded,
                  label: 'event_type'.tr,
                  value: controller.eventName,
                  primary: primary,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.notes_rounded,
                  label: 'special_note'.tr,
                  value: controller.note.isEmpty ? 'none'.tr : controller.note,
                  primary: primary,
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.history_rounded,
                  label: 'order_creation_time'.tr,
                  value: controller.createdAt,
                  primary: primary,
                ),
              ],
            ),
          ),
          Obx(
            () => _buildSummaryTile(
              context,
              icon: Icons.handshake_rounded,
              label: 'chosen_partner'.tr,
              value: controller.partnerName,
              primary: primary,
              trailing: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => _buildSummaryTile(
              context,
              icon: Icons.payments_rounded,
              label: 'sealing_price'.tr,
              value:
                  '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(controller.finalTotal)} đ',
              primary: primary,
              valueColor: AppColors.red700,
              valueStyle: context.typography.lg,
            ),
          ),
          Obx(() {
            final String? usedVoucherCode = controller.usedVoucherCode;
            final bool showsVoucherInput =
                !controller.isHistory.value &&
                controller.status != 'confirmed' &&
                controller.status != 'in_job';

            if (usedVoucherCode == null || showsVoucherInput) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildSummaryTile(
                context,
                icon: Icons.local_offer_rounded,
                label: 'used_voucher'.tr,
                value: usedVoucherCode,
                primary: const Color(0xFF16A34A),
                valueColor: const Color(0xFF166534),
                trailing: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Obx(() {
            if (!controller.isHistory.value &&
                controller.status != 'confirmed' &&
                controller.status != 'in_job') {
              return _buildVoucherSection(context, primary);
            }

            final double discount = controller.total - controller.finalTotal;
            if (discount <= 0) {
              return const SizedBox.shrink();
            }

            return _buildDiscountBox(context, discount);
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryAvatar(BuildContext context, Color primary) {
    return Container(
      height: 72,
      width: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: (controller.categoryImage ?? '').isNotEmpty
            ? CachedNetworkImage(
                imageUrl: controller.categoryImage ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: primary.withValues(alpha: 0.08),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: primary,
                  ),
                ),
              )
            : Container(
                color: primary.withValues(alpha: 0.08),
                child: Icon(Icons.category_rounded, color: primary),
              ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color primary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBubble(icon, primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.typography.xs.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: context.typography.sm.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color primary,
    Color? valueColor,
    TextStyle? valueStyle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primary.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildIconBubble(icon, primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.typography.xs.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: (valueStyle ?? context.typography.sm).copyWith(
                    color: valueColor ?? const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _buildIconBubble(IconData icon, Color primary) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: primary, size: 19),
    );
  }

  Widget _buildVoucherSection(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'apply_voucher_code'.tr,
            style: context.typography.xs.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                final bool hasUsedVoucher = controller.usedVoucherCode != null;
                final bool hasSavedVoucher =
                    ClientOrderDetailState.savedVouchers[controller.orderId] !=
                        null;
                final Widget field = _buildVoucherField(
                  primary,
                  readOnly: hasSavedVoucher || hasUsedVoucher,
                );
                final Widget button = hasSavedVoucher || hasUsedVoucher
                    ? _buildRemoveVoucherButton()
                    : _buildVoucherButton(primary);

                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [field, const SizedBox(height: 8), button],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 8),
                    button,
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherField(Color primary, {required bool readOnly}) {
    return TextField(
      readOnly: readOnly,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      controller: controller.voucherController,
      decoration: InputDecoration(
        hintText: 'voucher_placeholder'.tr,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        suffixIcon: readOnly
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _buildVoucherButton(Color primary) {
    return Obx(
      () => ElevatedButton(
        onPressed: controller.isCheckingVoucher.value
            ? null
            : () => controller.checkVoucher(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: controller.isCheckingVoucher.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'check_and_save_code'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildRemoveVoucherButton() {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: controller.isRemovingVoucher.value
            ? null
            : () => controller.removeVoucher(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red700,
          side: const BorderSide(color: AppColors.red200),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: controller.isRemovingVoucher.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.close_rounded, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'remove_voucher'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountBox(BuildContext context, double discount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${'discounted'.tr}: ${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(discount)} đ',
        style: context.typography.sm.copyWith(
          color: const Color(0xFF166534),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
