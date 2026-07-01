import 'package:sukientotapp/core/utils/import/global.dart';
import 'controller.dart';
import 'widget/chat_app_bar.dart';
import 'widget/chat_bubble.dart';
import 'widget/chat_input.dart';

class MessageDetailScreen extends GetView<MessageController> {
  const MessageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: const ChatAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value &&
                  controller.messagesDetail.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                );
              }
              return Column(
                children: [
                  Obx(() {
                    if (!controller.isLoadingOlderMessages.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: ListView.builder(
                      controller: controller.scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: controller.messagesDetail.length + 1,
                      itemBuilder: (context, index) {
                        // Last item (visually at top) = security notice
                        if (index == controller.messagesDetail.length) {
                          return const _SecurityNotice()
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(
                                begin: -0.05,
                                end: 0,
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              );
                        }
                        final message = controller.messagesDetail[index];
                        return ChatBubble(
                              message: message,
                              isFirst:
                                  index == controller.messagesDetail.length - 1,
                            )
                            .animate(delay: (50 * index).ms)
                            .fadeIn(duration: 500.ms)
                            .slideY(
                              begin: -0.02,
                              end: 0,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
          ChatInput(controller: controller),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFE53935), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text.rich(
        // style: TextStyle(fontSize: 12, color: Color(0xFF7B1010), height: 1.5),
        textAlign: TextAlign.center,
        TextSpan(
          style: TextStyle(fontSize: 12, color: Color(0xFF7B1010), height: 1.5),
          children: [
            TextSpan(
              text: 'Bảo mật thông tin: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  'Vui lòng không chia sẻ số điện thoại, zalo hay thông tin cá nhân khác để đảm bảo an toàn cho chính bạn. Giao dịch qua ứng dụng: mọi thỏa thuận về giá cả, công việc phát sinh hoặc thay đổi lịch hẹn đều cần được xác nhận trên ứng dụng.\n',
            ),
            TextSpan(
              text: 'Đảm bảo quyền lợi: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  'sukientot.com chỉ bảo vệ và hỗ trợ các vấn đề (bảo hành, khiếu nại) dựa trên các giao dịch được ghi nhận chính thức trên ứng dụng.\n',
            ),
            TextSpan(
              text: 'Báo cáo vi phạm: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  'Nếu CTV sukientot.com có bất kỳ yêu cầu giao dịch riêng nào, hãy báo cáo ngay cho chúng tôi qua hotline ',
            ),
            TextSpan(
              text: '0393719095',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
