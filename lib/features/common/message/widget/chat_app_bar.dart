import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/call/widgets/call_ui.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/common/message/widget/member_invitation_sheet.dart';
import 'package:sukientotapp/features/common/report/report_bottom_sheet.dart';
import 'package:sukientotapp/features/common/call/widgets/call_ui.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final colors = context.fTheme.colors;
    final controller = Get.find<MessageController>();

    return AppBar(
      backgroundColor: colors.background,
      automaticallyImplyLeading: false,
      toolbarHeight: 84,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          color: colors.border.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      titleSpacing: 12,
      title: Obx(() {
        final thread = controller.selectedThread.value;
        if (thread == null) return const SizedBox.shrink();

        return Row(
          children: [
            _HeaderActionButton(
              tooltip: 'Quay lại',
              onPressed: Get.back,
              icon: FIcons.arrowLeft,
              foregroundColor: colors.foreground,
              backgroundColor: colors.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.subject.isEmpty
                        ? thread.bill.eventName
                        : thread.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ThreadMetaLine(
                    icon: FIcons.calendarDays,
                    text: '${thread.bill.eventName} · ${thread.bill.datetime}',
                  ),
                  if (thread.bill.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _ThreadMetaLine(
                      icon: FIcons.mapPin,
                      text: thread.bill.address,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CallActionButton(
              context: context,
              controller: controller,
            ),
            const SizedBox(width: 6),
            _ChatOptionsButton(
              context: context,
              controller: controller,
              onLeave: () => _confirmLeave(context, controller),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    MessageController controller,
  ) async {
    final leftThread = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời đoạn chat?'),
        content: const Text(
          'Bạn sẽ không thể đọc hoặc gửi tin nhắn sau khi rời. Bạn chỉ có thể tham gia lại khi được mời.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          Obx(
            () => TextButton(
              onPressed: controller.isLeavingThread.value
                  ? null
                  : () async {
                      final success = await controller.leaveSelectedThread();
                      if (success && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
              child: controller.isLeavingThread.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Rời', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
    if (leftThread == true && context.mounted) {
      await Navigator.of(context).maybePop();
    }
  }
}

class _ThreadMetaLine extends StatelessWidget {
  const _ThreadMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.fTheme.colors.mutedForeground;
    return Row(
      children: [
        Icon(icon, size: 11, color: muted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 11, height: 1.2),
          ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 19),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({required this.context, required this.controller});

  final BuildContext context;
  final MessageController controller;

  @override
  Widget build(BuildContext buildContext) {
    final colors = buildContext.fTheme.colors;
    final thread = controller.selectedThread.value!;
    final coordinator = controller.callCoordinator;
    final hasCall = coordinator.activeCall.value != null;

    return _HeaderActionButton(
      tooltip: hasCall ? 'Mở cuộc gọi' : 'Gọi âm thanh',
      foregroundColor: hasCall
          ? const Color(0xFF059669)
          : colors.foreground,
      backgroundColor: hasCall
          ? const Color(0xFFECFDF5)
          : colors.secondary,
      icon: hasCall ? Icons.call_rounded : Icons.add_call,
      onPressed: () async {
        if (hasCall) {
          final connected =
              coordinator.localState.value == LocalCallState.connected ||
              coordinator.localState.value == LocalCallState.reconnecting;
          if (!connected) {
            final session = await coordinator.joinActiveCall();
            if (session == null) return;
          }
          await openAudioCallScreen();
          return;
        }
        if (context.mounted) {
          await showStartCallSheet(
            context: context,
            thread: thread,
            coordinator: coordinator,
          );
        }
      },
    );
  }
}

class _ChatOptionsButton extends StatelessWidget {
  const _ChatOptionsButton({
    required this.context,
    required this.controller,
    required this.onLeave,
  });

  final BuildContext context;
  final MessageController controller;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext buildContext) {
    final colors = buildContext.fTheme.colors;
    final thread = controller.selectedThread.value!;

    return Tooltip(
      message: 'Tùy chọn đoạn chat',
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 8),
        elevation: 8,
        color: colors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 240),
        onSelected: (value) async {
          if (value == 'invite') {
            await showMemberInvitationSheet(controller);
          } else if (value == 'leave' && context.mounted) {
            await onLeave();
          } else if (value == 'report') {
            await showReportBottomSheet(
              reportedBillId: thread.bill.id,
              billCode: thread.code,
            );
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem<String>(
            value: 'invite',
            child: _MenuAction(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Mời thành viên',
            ),
          ),
          const PopupMenuItem<String>(
            value: 'report',
            child: _MenuAction(
              icon: Icons.flag_outlined,
              label: 'Báo cáo',
            ),
          ),
          if (thread.canLeave) ...[
            const PopupMenuDivider(height: 8),
            const PopupMenuItem<String>(
              value: 'leave',
              child: _MenuAction(
                icon: Icons.logout_rounded,
                label: 'Rời đoạn chat',
                destructive: true,
              ),
            ),
          ],
        ],
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.65),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 22,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFDC2626)
        : context.fTheme.colors.foreground;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
