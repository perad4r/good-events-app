import 'package:flutter/services.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

import '../controller.dart';

class _CurrencyInputFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.parse(digits);
    final formatted = _fmt.format(number).replaceAll(',', '.');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static double? parse(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }
}

class Accept extends StatefulWidget {
  const Accept({super.key, required this.code, required this.billId});

  final String code;
  final int billId;

  @override
  State<Accept> createState() => _AcceptState();
}

class _AcceptState extends State<Accept> {
  final _priceController = TextEditingController();
  final _currencyFormatter = _CurrencyInputFormatter();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final price = _CurrencyInputFormatter.parse(_priceController.text);
    if (price == null || price < 10000) {
      AppSnackbar.showError(
        message: 'invalid_price'.trParams({'min': '10.000'}),
        title: 'error'.tr,
      );
      return;
    }

    final controller = Get.find<NewShowController>();
    final success = await controller.acceptBill(
      billId: widget.billId,
      price: price,
    );

    if (success) {
      Get.back();
      AppSnackbar.showSuccess(
        message: 'price_quoted'.trParams({'code': widget.code}),
        title: 'success'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FTheme.of(context).colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FTheme.of(context).colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      FIcons.badgeCheck,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'price_quote'.tr,
                          style: FTheme.of(context).typography.base.copyWith(
                            fontWeight: FontWeight.w700,
                            color: FTheme.of(context).colors.foreground,
                          ),
                        ),
                        Text(
                          'price_quote_for_show'.trParams({
                            'code': widget.code,
                          }),
                          style: FTheme.of(context).typography.xs.copyWith(
                            color: FTheme.of(context).colors.mutedForeground,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: FTheme.of(context).colors.border),

            // Input + button
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price label
                    Text(
                      'input_price_quote'.tr,
                      style: FTheme.of(context).typography.xs.copyWith(
                        color: FTheme.of(context).colors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      inputFormatters: [_currencyFormatter],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: FTheme.of(context).colors.muted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: FTheme.of(context).colors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: FTheme.of(context).colors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1.5,
                          ),
                        ),
                        hintText: '0',
                        hintStyle: FTheme.of(context).typography.base.copyWith(
                          color: FTheme.of(context).colors.mutedForeground,
                        ),
                        suffixText: 'VND',
                        suffixStyle: FTheme.of(context).typography.sm.copyWith(
                          color: FTheme.of(context).colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: FTheme.of(context).typography.base.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Obx(() {
                final ctrl = Get.find<NewShowController>();
                final accepting = ctrl.isAccepting.value;
                return GestureDetector(
                  onTap: () {
                    if (!accepting) _onSubmit();
                  },
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: accepting
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: accepting ? FTheme.of(context).colors.muted : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: accepting
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (accepting)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FTheme.of(context).colors.mutedForeground,
                            ),
                          )
                        else
                          const Icon(
                            FIcons.badgeCheck,
                            size: 16,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          accepting ? 'loading'.tr : 'apply_for_show'.tr,
                          style: FTheme.of(context).typography.sm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accepting
                                ? FTheme.of(context).colors.mutedForeground
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
