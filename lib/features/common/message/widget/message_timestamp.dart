import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/message_model.dart';

import '../controller.dart';

/// Only the relative-time label listens to the active chat's shared clock.
class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({super.key, required this.message, this.style});

  final MessageModel message;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MessageController>()) {
      return Text(message.time, style: style);
    }
    final MessageController controller = Get.find<MessageController>();
    return Obx(
      () => Text(message.timeAt(controller.messageTimeNow.value), style: style),
    );
  }
}
