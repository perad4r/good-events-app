import 'package:get/get.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';

class NotificationHandler {
  static void handleMessage(Map<String, dynamic> data) {
    final code = data['code'];
    if (code != null) {
      switch (code) {
        case 'NEW_BILL_DETAIL':
          NotificationHandler().handleNewBillDetailCode(data);
          break;
        case 'BILL_CONFIRMED':
          NotificationHandler().handleBillConfirmedCode(data);
          break;
        case 'BILL_RECEIVED':
          NotificationHandler().handleBillReceivedCode(data);
          break;
        case 'TEST_NOTIFICATION':
          logger.i(
            '[NotificationHandler] Received test notification with data: $data',
          );
          break;
        default:
          logger.w('[NotificationHandler] Unknown code: $code');
      }
    } else {
      logger.w('[NotificationHandler] Received message without code: $data');
    }
  }

  void handleNewBillDetailCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling new bill detail');

    if (Get.isRegistered<ClientOrderController>()) {
      Get.find<ClientOrderController>().fetchEventOrders();
    } else {
      logger.w(
        '[NotificationHandler] ClientOrderController not registered, cannot update order details',
      );
    }
  }

  void handleBillConfirmedCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling bill confirmed');

    if (Get.isRegistered<ShowController>()) {
      Get.find<ShowController>().refreshUpcomingBills();
    } else {
      logger.w(
        '[NotificationHandler] ShowController not registered, cannot update upcoming bills',
      );
    }
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling bill received');

    //Do nothing =D
  }
}
