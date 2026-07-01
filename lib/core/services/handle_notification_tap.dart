import 'package:get/get.dart';
import 'package:sukientotapp/core/routes/pages.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/features/client/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/partner/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/partner/new_show/controller.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';

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
        case 'NEW_REVIEW_RECEIVED':
          HandleNotificationTap().handleNewReviewReceivedCode(data);
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
    _openClientOrdersScreen();
  }

  void handleBillConfirmedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for bill confirmed');
    _openPartnerShowScreen(showTabIndex: 1);
  }

  void handleBillReceivedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for bill received');
    _openNewShowScreen();
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

  void handleNewReviewReceivedCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Handling tap for new review received');
    if (Get.currentRoute == Routes.partnerReviews) {
      return;
    }
    Get.toNamed(Routes.partnerReviews);
  }

  void _openNewShowScreen() {
    const newShowTabIndex = 2;

    if (Get.isRegistered<PartnerBottomNavigationController>()) {
      Get.find<PartnerBottomNavigationController>().setIndex(newShowTabIndex);

      if (Get.currentRoute != Routes.partnerHome) {
        Get.offAllNamed(
          Routes.partnerHome,
          arguments: {'initialIndex': newShowTabIndex},
        );
      }
    } else {
      Get.offAllNamed(
        Routes.partnerHome,
        arguments: {'initialIndex': newShowTabIndex},
      );
    }

    if (Get.isRegistered<NewShowController>()) {
      Get.find<NewShowController>().refreshBills();
    } else {
      logger.w(
        '[HandleNotificationTap] NewShowController not registered, cannot refresh new shows',
      );
    }
  }

  void _openPartnerShowScreen({required int showTabIndex}) {
    const partnerShowBottomTabIndex = 1;
    final arguments = {
      'initialIndex': partnerShowBottomTabIndex,
      'initialShowTabIndex': showTabIndex,
    };

    if (Get.isRegistered<PartnerBottomNavigationController>()) {
      Get.find<PartnerBottomNavigationController>().setIndex(
        partnerShowBottomTabIndex,
        setTab: showTabIndex,
      );

      if (Get.currentRoute != Routes.partnerHome) {
        Get.offAllNamed(Routes.partnerHome, arguments: arguments);
      }
    } else {
      Get.offAllNamed(Routes.partnerHome, arguments: arguments);
    }

    if (Get.isRegistered<ShowController>()) {
      Get.find<ShowController>().refreshUpcomingBills();
    } else {
      logger.w(
        '[HandleNotificationTap] ShowController not registered, cannot refresh upcoming bills',
      );
    }
  }

  void _openClientOrdersScreen() {
    const clientOrdersTabIndex = 1;

    if (Get.isRegistered<ClientBottomNavigationController>()) {
      Get.find<ClientBottomNavigationController>().setIndex(
        clientOrdersTabIndex,
      );

      if (Get.currentRoute != Routes.clientHome) {
        Get.offAllNamed(
          Routes.clientHome,
          arguments: {'initialIndex': clientOrdersTabIndex},
        );
      }
    } else {
      Get.offAllNamed(
        Routes.clientHome,
        arguments: {'initialIndex': clientOrdersTabIndex},
      );
    }

    if (Get.isRegistered<ClientOrderController>()) {
      Get.find<ClientOrderController>().fetchEventOrders();
    } else {
      logger.w(
        '[HandleNotificationTap] ClientOrderController not registered, cannot refresh event orders',
      );
    }
  }
}
