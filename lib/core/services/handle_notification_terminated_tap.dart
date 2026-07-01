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
        case 'NEW_REVIEW_RECEIVED':
          HandleNotificationTerminatedTap().handleNewReviewReceivedCode(data);
          break;
        default:
          logger.w('[HandleNotificationTerminatedTap] Unknown code: $code');
      }
    } else {
      logger.w(
        '[HandleNotificationTerminatedTap] Received tap without code: $data',
      );
    }
  }

  void handleNewBillDetailCode(Map<String, dynamic> data) {
    logger.i(
      '[HandleNotificationTerminatedTap] Handling tap for new bill detail',
    );
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingClientTabIndex,
      value: '1',
    );
    logger.i('[HandleNotificationTerminatedTap] Saved pendingClientTabIndex=1');
  }

  void handleBillConfirmedCode(Map<String, dynamic> data) {
    logger.i(
      '[HandleNotificationTerminatedTap] Handling tap for bill confirmed',
    );
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingPartnerTabIndex,
      value: '1',
    );
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingPartnerShowTabIndex,
      value: '1',
    );
    logger.i(
      '[HandleNotificationTerminatedTap] Saved pendingPartnerTabIndex=1, pendingPartnerShowTabIndex=1',
    );
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i(
      '[HandleNotificationTerminatedTap] Handling tap for bill received',
    );
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingPartnerTabIndex,
      value: '2',
    );
    StorageService.removeData(key: LocalStorageKeys.pendingPartnerShowTabIndex);
    logger.i(
      '[HandleNotificationTerminatedTap] Saved pendingPartnerTabIndex=2',
    );
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

  void handleNewReviewReceivedCode(Map<String, dynamic> data) {
    logger.i(
      '[HandleNotificationTerminatedTap] Handling tap for new review received',
    );
    StorageService.writeStringData(
      key: LocalStorageKeys.pendingPartnerRoute,
      value: LocalStorageKeys.pendingPartnerRouteReviews,
    );
    logger.i(
      '[HandleNotificationTerminatedTap] Saved pendingPartnerRoute=reviews',
    );
  }
}
