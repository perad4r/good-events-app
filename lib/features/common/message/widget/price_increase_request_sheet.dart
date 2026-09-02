import 'package:flutter/services.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller.dart';

Future<void> showPriceIncreaseRequestSheet(MessageController controller) async {
  final formKey = GlobalKey<FormState>();
  String priceText = '';
  String reasonText = '';
  final currencyFormatter = _CurrencyInputFormatter();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(Get.context!).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tạo yêu cầu tăng giá', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text('Gửi mức giá mới để khách hàng xem xét', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _CurrentPriceCard(total: controller.selectedThread.value?.bill.total),
                const SizedBox(height: 20),
                const Text('Tổng giá đề nghị', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                TextFormField(
                  onChanged: (value) => priceText = value.replaceAll(RegExp(r'[^0-9]'), ''),
                  keyboardType: TextInputType.number,
                  inputFormatters: [currencyFormatter],
                  style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.055),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    final price = int.tryParse((value ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                    if (price == null || price <= 0) return 'Vui lòng nhập giá hợp lệ';
                    final current = controller.selectedThread.value?.bill.total;
                    if (current != null && price <= current) return 'Giá mới phải lớn hơn ${NumberFormat.decimalPattern('vi_VN').format(current)} ₫';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text('Lý do điều chỉnh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                TextFormField(
                  onChanged: (value) => reasonText = value,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Khách bổ sung thêm hạng mục...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final success = await controller.sendPriceIncreaseRequest(
                      requestedPrice: int.parse(priceText),
                      reason: reasonText,
                    );
                    if (success) {
                      Get.back<void>();
                      AppSnackbar.showSuccess(
                        message: 'Đã gửi yêu cầu tăng giá.',
                      );
                    }
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Text('Gửi yêu cầu tăng giá', style: TextStyle(fontWeight: FontWeight.w700))),
                )),
              ]),
            ),
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _CurrentPriceCard extends StatelessWidget {
  const _CurrentPriceCard({required this.total});

  final int? total;

  @override
  Widget build(BuildContext context) {
    final String value = total == null
        ? 'Chưa có thông tin'
        : '${NumberFormat.decimalPattern('vi_VN').format(total)} ₫';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.11),
            AppColors.primary.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 21),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Giá hiện tại của đơn', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
          ),
          Text(value, style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final int? value = int.tryParse(digits);
    if (value == null) return oldValue;
    final String formatted = _formatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
