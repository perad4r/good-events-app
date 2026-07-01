import 'package:sukientotapp/core/utils/import/global.dart';

import 'controller.dart';
import 'widget/header.dart';
import 'detail_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late final MessageController controller;
  late final RefreshController refreshController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MessageController>();
    refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      header: Header(controller: controller),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.fTheme.colors.muted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    FIcons.mailOpen,
                    size: 32,
                    color: context.fTheme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_messages'.tr,
                  style: context.typography.base.copyWith(
                    color: context.fTheme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'no_messages_desc'.tr,
                  style: context.typography.sm.copyWith(
                    color: context.fTheme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }

        return SmartRefresher(
          controller: refreshController,
          enablePullDown: true,
          enablePullUp: false,
          header: const ClassicHeader(),
          onRefresh: () async {
            await controller.refreshThreads();
            if (mounted) {
              refreshController.refreshCompleted();
            }
          },
          onLoading: () {
            refreshController.loadComplete();
          },
          child: ListView.builder(
            controller: controller.listScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: controller.filteredMessages.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.filteredMessages.length) {
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'no_further_messages'.tr,
                        style: context.typography.xs.copyWith(
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  );
                });
              }

              final message = controller.filteredMessages[index];
              final bool hasUnread = message.unreadMessages > 0;

              return GestureDetector(
                onTap: () async {
                  await controller.openThread(message);
                  await Get.to<void>(() => const MessageDetailScreen());
                  controller.closeThread();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? context.fTheme.colors.primary.withValues(alpha: 0.05)
                        : context.fTheme.colors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasUnread
                          ? context.fTheme.colors.primary.withValues(alpha: 0.2)
                          : context.fTheme.colors.border.withValues(alpha: 0.7),
                    ),
                    boxShadow: hasUnread
                        ? [
                            BoxShadow(
                              color: context.fTheme.colors.primary.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: hasUnread
                              ? context.fTheme.colors.primary.withValues(
                                  alpha: 0.12,
                                )
                              : context.fTheme.colors.muted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          FIcons.messageSquareText,
                          size: 18,
                          color: hasUnread
                              ? context.fTheme.colors.primary
                              : context.fTheme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    message.subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.typography.sm.copyWith(
                                      color: hasUnread
                                          ? context.fTheme.colors.foreground
                                          : context
                                                .fTheme
                                                .colors
                                                .mutedForeground,
                                      fontWeight: hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        if (message.newestMessageSender != null)
                                          TextSpan(
                                            text:
                                                '${message.newestMessageSender}: ',
                                            style: context.typography.xs
                                                .copyWith(
                                                  color: hasUnread
                                                      ? context
                                                            .fTheme
                                                            .colors
                                                            .primary
                                                      : context
                                                            .fTheme
                                                            .colors
                                                            .mutedForeground,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                          ),
                                        TextSpan(
                                          text:
                                              message.newestMessage ??
                                              'no_messages'.tr,
                                          style: context.typography.xs.copyWith(
                                            color: context
                                                .fTheme
                                                .colors
                                                .mutedForeground,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.fTheme.colors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${message.unreadMessages}',
                                      style: context.typography.xs.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Text(
                                  message.time,
                                  style: context.typography.xs.copyWith(
                                    color: hasUnread
                                        ? context.fTheme.colors.primary
                                        : context.fTheme.colors.mutedForeground,
                                    fontSize: 11,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
