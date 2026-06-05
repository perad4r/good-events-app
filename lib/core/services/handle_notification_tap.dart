import 'package:get/get.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/features/common/message/controller.dart';

class HandleNotificationTap {
  static void handleTap(Map<String, dynamic> data) {
    final code = data['code'];
    if (code != null) {
      switch (code) {
        case 'NEW_BILL_DETAIL':
          HandleNotificationTap().handleNewBillDetailCode(data);
          break;
        case 'BILL_CONFIRMED':
          HandleNotificationTap().handleBillConfirmedCode(data);
          break;
        case 'BILL_RECEIVED':
          HandleNotificationTap().handleBillReceivedCode(data);
          break;
        case 'NEW_MESSAGE':
          HandleNotificationTap().handleNewMessageCode(data);
          break;
        default:
          logger.w('[HandleNotificationTap] Unknown code: $code');
      }
    } else {
      logger.w('[HandleNotificationTap] Received tap without code: $data');
    }
  }

  void handleNewBillDetailCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for new bill detail');
  }

  void handleBillConfirmedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for bill confirmed');
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for bill received');
  }

  void handleNewMessageCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for new message');
    final threadId = data['thread_id']?.toString();
    if (threadId == null) {
      logger.w('[HandleNotificationTap] NEW_MESSAGE tap missing thread_id');
      return;
    }
    if (Get.isRegistered<MessageController>()) {
      Get.find<MessageController>().openThreadById(threadId);
    } else {
      logger.w(
        '[HandleNotificationTap] MessageController not registered, cannot open thread',
      );
    }
  }
}
