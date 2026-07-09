import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';

class BookingStageNavigation extends StatelessWidget {
  const BookingStageNavigation({
    super.key,
    required this.isFirstStage,
    required this.isLastStage,
    required this.isSubmitting,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirstStage;
  final bool isLastStage;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final leftButton = CustomButtonPlus(
      onTap: _handleLeftTap,
      btnText: _leftLabel,
      color: Colors.white,
      textColor: AppColors.lightForeground,
      borderColor: context.fTheme.colors.border,
      fontWeight: FontWeight.w600,
      isDisabled: isSubmitting,
    );

    final rightButton = CustomButtonPlus(
      onTap: _handleRightTap,
      btnText: _rightLabel,
      color: AppColors.red600,
      textColor: Colors.white,
      borderColor: Colors.transparent,
      fontWeight: FontWeight.w700,
      isLoading: isSubmitting,
      isDisabled: isSubmitting,
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(142, 0, 0, 0).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: leftButton),
            const SizedBox(width: 10),
            Expanded(child: rightButton),
          ],
        ),
      ),
    );
  }

  String get _leftLabel {
    if (isFirstStage) return 'cancel'.tr;
    return 'previous'.tr;
  }

  String get _rightLabel {
    if (isLastStage) return 'booking_submit'.tr;
    return 'next'.tr;
  }

  void _handleLeftTap() {
    if (isFirstStage) {
      onBack();
      return;
    }
    onPrevious();
  }

  void _handleRightTap() {
    if (isLastStage) {
      onSubmit();
      return;
    }
    onNext();
  }
}
