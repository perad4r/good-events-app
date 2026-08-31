import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/components/button/plus.dart';
import 'package:upgrader/upgrader.dart';

class AppUpgradeAlert extends StatefulWidget {
  const AppUpgradeAlert({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpgradeAlert> createState() => _AppUpgradeAlertState();
}

class _AppUpgradeAlertState extends State<AppUpgradeAlert> {
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      // debugDisplayAlways: kDebugMode,
      // debugLogging: kDebugMode,
    );
  }

  @override
  void dispose() {
    _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BrandedUpgradeAlert(
      upgrader: _upgrader,
      navigatorKey: Get.key,
      showIgnore: false,
      showLater: false,
      child: widget.child,
    );
  }
}

class _BrandedUpgradeAlert extends UpgradeAlert {
  _BrandedUpgradeAlert({
    required super.upgrader,
    required super.navigatorKey,
    required super.showIgnore,
    required super.showLater,
    required super.child,
  });

  @override
  UpgradeAlertState createState() => _BrandedUpgradeAlertState();
}

class _BrandedUpgradeAlertState extends UpgradeAlertState {
  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    final isBlocked = widget.upgrader.blocked();
    final showIgnore = !isBlocked && widget.showIgnore;
    final showLater = !isBlocked && widget.showLater;
    final colors = context.fTheme.colors;

    return Dialog(
      key: key,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    FIcons.refreshCw,
                    size: 30,
                    color: AppColors.red600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  key: const Key('upgrader.dialog.title'),
                  textAlign: TextAlign.center,
                  style: context.typography.xl.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.typography.sm.copyWith(
                    color: colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                if (widget.showPrompt) ...[
                  const SizedBox(height: 10),
                  Text(
                    messages.message(UpgraderMessage.prompt) ?? '',
                    textAlign: TextAlign.center,
                    style: context.typography.sm.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
                if (releaseNotes?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          messages.message(UpgraderMessage.releaseNotes) ?? '',
                          style: context.typography.sm.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Text(
                              releaseNotes!,
                              style: context.typography.xs.copyWith(
                                color: colors.mutedForeground,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonPlus(
                    onTap: () => onUserUpdated(context, !isBlocked),
                    btnText:
                        messages.message(UpgraderMessage.buttonTitleUpdate) ??
                        'Cập nhật ngay',
                    icon: FIcons.refreshCw,
                    height: 48,
                    borderRadius: 12,
                    borderColor: Colors.transparent,
                    fontWeight: FontWeight.w700,
                    textSize: 14,
                  ),
                ),
                if (showIgnore || showLater) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showIgnore)
                        TextButton(
                          onPressed: () => onUserIgnored(context, true),
                          child: Text(
                            messages.message(
                                  UpgraderMessage.buttonTitleIgnore,
                                ) ??
                                'Bỏ qua',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ),
                      if (showIgnore && showLater)
                        Container(
                          width: 1,
                          height: 16,
                          color: colors.border,
                        ),
                      if (showLater)
                        TextButton(
                          onPressed: () => onUserLater(context, true),
                          child: Text(
                            messages.message(
                                  UpgraderMessage.buttonTitleLater,
                                ) ??
                                'Để sau',
                            style: TextStyle(
                              color: colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
