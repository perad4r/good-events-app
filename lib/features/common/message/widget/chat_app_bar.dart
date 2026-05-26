import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/common/report/report_bottom_sheet.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    final colors = context.fTheme.colors;
    return AppBar(
      backgroundColor: colors.background,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: colors.border.withValues(alpha: 0.6), width: 0.5),
      ),
      titleSpacing: 12,
      title: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F4F6),
              ),
              child: Center(
                child: Icon(FIcons.arrowLeft, size: 18, color: colors.foreground),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Icon(FIcons.messageCircleMore, size: 20, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          // Thread info
          Expanded(
            child: Obx(() {
              final thread = Get.find<MessageController>().selectedThread.value;
              if (thread == null) return const SizedBox.shrink();
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.subject,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(FIcons.calendarDays, size: 11, color: colors.mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${thread.bill.eventName} · ${thread.bill.datetime}',
                          style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(FIcons.mapPin, size: 11, color: colors.mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          thread.bill.address,
                          style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 9),
          Obx(() {
            final thread = Get.find<MessageController>().selectedThread.value;
            if (thread == null) {
              return const SizedBox.shrink();
            }

            return IconButton(
              onPressed: () => showReportBottomSheet(
                reportedBillId: thread.bill.id,
                billCode: thread.code,
              ),
              tooltip: 'report'.tr,
              icon: Icon(
                Icons.flag_outlined,
                color: colors.mutedForeground,
                size: 20,
              ),
            );
          }),
        ],
      ),
    );
  }
}
