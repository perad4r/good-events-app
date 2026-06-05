import 'package:get/get.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';

class HandleNotificationTerminatedTap {
  static void handleTap(Map<String, dynamic>? data) {
    if (data == null) {
      logger.w('[HandleNotificationTerminatedTap] Received tap with null data');
      return;
    }
    final code = data['code'];
    if (code != null) {
      switch (code) {
        case 'NEW_BILL_DETAIL':
          HandleNotificationTerminatedTap().handleNewBillDetailCode(data);
          break;
        case 'BILL_CONFIRMED':
          HandleNotificationTerminatedTap().handleBillConfirmedCode(data);
          break;
        case 'BILL_RECEIVED':
          HandleNotificationTerminatedTap().handleBillReceivedCode(data);
          break;
        case 'NEW_MESSAGE':
          HandleNotificationTerminatedTap().handleNewMessageCode(data);
          break;
        default:
          logger.w('[HandleNotificationTerminatedTap] Unknown code: $code');
      }
    } else {
      logger.w('[HandleNotificationTerminatedTap] Received tap without code: $data');
    }
  }

  void handleNewBillDetailCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTerminatedTap] Handling tap for new bill detail');
  }

  void handleBillConfirmedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTerminatedTap] Handling tap for bill confirmed');
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTerminatedTap] Handling tap for bill received');
  }

  void handleNewMessageCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTerminatedTap] Handling tap for new message');
    final threadId = data['thread_id']?.toString();
    if (threadId == null) {
      logger.w(
        '[HandleNotificationTerminatedTap] NEW_MESSAGE tap missing thread_id',
      );
      return;
    }
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingThreadId,
      value: threadId,
    );
    logger.i(
      '[HandleNotificationTerminatedTap] Saved pendingThreadId=$threadId',
    );
  }
}
