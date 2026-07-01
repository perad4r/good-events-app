import 'package:get/get.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/partner/home/controller.dart';
import 'package:sukientotapp/features/partner/reviews/controller.dart';

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
        case 'NEW_MESSAGE':
          NotificationHandler().handleNewMessageCode(data);
          break;
        case 'NEW_REVIEW_RECEIVED':
          NotificationHandler().handleNewReviewReceivedCode(data);
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
      Get.find<ShowController>().refreshNewBills();
    } else {
      logger.w(
        '[NotificationHandler] ShowController not registered, cannot update upcoming bills',
      );
    }

    if (Get.isRegistered<PartnerHomeController>()) {
      Get.find<PartnerHomeController>().updateShowDataOnConfirmedByClient();
    } else {
      logger.w(
        '[NotificationHandler] PartnerHomeController not registered, cannot update bills',
      );
    }

    if (Get.isRegistered<MessageController>()) {
      Get.find<MessageController>().refreshThreads();
    } else {
      logger.w(
        '[NotificationHandler] MessageController not registered, cannot update message threads',
      );
    }
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling bill received');

    //Do nothing =D
  }

  void handleNewMessageCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling new message');
    final threadId = data['thread_id'];
    if (threadId == null) {
      logger.w(
        '[NotificationHandler] New message code received without threadId',
      );
      return;
    } else {
      logger.i('[NotificationHandler] New message for threadId: $threadId');
    }
  }

  void handleNewReviewReceivedCode(Map<String, dynamic> data) {
    logger.i('[NotificationHandler] Handling new review received');

    if (Get.isRegistered<PartnerReviewsController>()) {
      Get.find<PartnerReviewsController>().fetchReviews(refresh: true);
    } else {
      logger.w(
        '[NotificationHandler] PartnerReviewsController not registered, cannot refresh reviews',
      );
    }
  }
}
