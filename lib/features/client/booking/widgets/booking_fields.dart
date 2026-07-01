import 'package:sukientotapp/core/utils/import/global.dart';

class BookingSelectField extends StatelessWidget {
  const BookingSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.leading,
    this.trailing,
    this.errorText,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData? leading;
  final IconData? trailing;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value.trim().isNotEmpty;
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final Color borderColor = hasError
        ? context.fTheme.colors.destructive
        : hasValue
            ? AppColors.red600.withValues(alpha: 0.28)
            : context.fTheme.colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: hasError ? context.fTheme.colors.destructive : null,
          ),
        ),
        const SizedBox(height: 6),
        FTappable(
          onPress: isLoading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.red600.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      leading,
                      size: 16,
                      color: hasValue
                          ? AppColors.red600
                          : AppColors.red600.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    style: context.typography.base.copyWith(
                      color: hasValue
                          ? context.fTheme.colors.foreground
                          : context.fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.fTheme.colors.mutedForeground,
                      ),
                    ),
                  )
                else
                  Icon(
                    trailing ?? FIcons.chevronDown,
                    size: 18,
                    color: hasValue
                        ? AppColors.red600
                        : context.fTheme.colors.mutedForeground,
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: context.typography.sm.copyWith(
              color: context.fTheme.colors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

class BookingTextField extends StatelessWidget {
  const BookingTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.errorText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: hasError ? context.fTheme.colors.destructive : null,
          ),
        ),
        const SizedBox(height: 6),
        FTextFormField(
          control: FTextFieldControl.managed(controller: controller),
          style: (FTextFieldStyle style) => style.copyWith(
            fillColor: Colors.white,
            filled: true,
          ),
          hint: hint,
          maxLines: maxLines,
          autovalidateMode: hasError
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          validator: (_) => hasError ? errorText : null,
        ),
      ],
    );
  }
}
