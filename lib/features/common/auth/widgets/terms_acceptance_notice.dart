import 'package:flutter/gestures.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

class TermsAcceptanceNotice extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsAcceptanceNotice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TermsAcceptanceNotice> createState() => _TermsAcceptanceNoticeState();
}

class _TermsAcceptanceNoticeState extends State<TermsAcceptanceNotice> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTermsOfUse;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _openTermsOfUse() {
    Get.toNamed(
      Routes.webView,
      arguments: {
        'url': 'https://sukientot.com/terms-and-condition',
        'title': 'terms_of_use'.tr,
      },
    );
  }

  void _openPrivacyPolicy() {
    Get.toNamed(
      Routes.webView,
      arguments: {
        'url': 'https://sukientot.com/privacy-policy',
        'title': 'privacy_policy'.tr,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fTheme.colors;
    final bodyStyle = context.typography.sm.copyWith(
      color: colors.mutedForeground,
      height: 1.45,
    );
    final linkStyle = bodyStyle.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
    );

    return FCheckbox(
      value: widget.value,
      onChange: widget.onChanged,
      label: RichText(
        text: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: 'terms_acceptance_text'.tr),
            TextSpan(
              text: 'terms_of_use'.tr,
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
            TextSpan(text: ' ${'and'.tr} '),
            TextSpan(
              text: 'privacy_policy'.tr,
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      description: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'terms_zero_tolerance_notice'.tr,
          style: context.typography.xs.copyWith(
            color: colors.mutedForeground,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
