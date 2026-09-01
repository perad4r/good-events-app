import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sukientotapp/core/routes/pages.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/features/client/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import 'package:sukientotapp/features/partner/bottom_navigation/controller.dart';
import 'package:sukientotapp/features/partner/new_show/controller.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/features/common/message/widget/invitation_accept_dialog.dart';

class HandleNotificationTap {
  static void handleTap(Map<String, dynamic> data) {
    if (data['type']?.toString() == 'incoming_call') {
      if (Get.isRegistered<CallCoordinator>()) {
        Get.find<CallCoordinator>().handleIncomingNotification(data);
      }
      return;
    }
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
        case 'CHAT_INVITATION':
          HandleNotificationTap().handleChatInvitationCode(data);
          break;
        case 'NEW_REVIEW_RECEIVED':
          HandleNotificationTap().handleNewReviewReceivedCode(data);
          break;
        case 'BILL_COMPLETED_REMINDER':
          openPartnerActiveBills();
          break;
        case 'PRICE_INCREASE_REQUEST_CREATED':
        case 'PRICE_INCREASE_REQUEST_STATUS_UPDATED':
          HandleNotificationTap().handlePriceIncreaseRequestCode(data);
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

  void handlePriceIncreaseRequestCode(Map<String, dynamic> data) {
    logger.i('[HandleNotificationTap] Opening price increase thread');
    handleNewMessageCode(data);
  }

  void handleChatInvitationCode(Map<String, dynamic> data) {
    final threadId = data['thread_id']?.toString();
    if (threadId == null || threadId.isEmpty) {
      logger.w('[HandleNotificationTap] CHAT_INVITATION missing thread_id');
      return;
    }

    if (!Get.isRegistered<MessageController>()) {
      StorageService.writeMapData(
        key: LocalStorageKeys.pendingChatInvitation,
        value: Map<String, dynamic>.from(data),
      );
      _openMessagesTab();
      return;
    }

    _openMessagesTab();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Get.isRegistered<MessageController>()) return;
      final controller = Get.find<MessageController>();
      final accepted = await showChatInvitationDialog(
        threadId: threadId,
        controller: controller,
        inviterName: data['inviter_name']?.toString(),
      );
      if (accepted && !controller.isClosed) {
        await controller.openThreadById(threadId);
      }
    });
  }

  void _openMessagesTab() {
    if (Get.isRegistered<ClientBottomNavigationController>()) {
      Get.find<ClientBottomNavigationController>().setIndex(2);
      return;
    }
    if (Get.isRegistered<PartnerBottomNavigationController>()) {
      Get.find<PartnerBottomNavigationController>().setIndex(3);
      return;
    }

    final role = StorageService.readMapData(
      key: LocalStorageKeys.user,
      mapKey: 'role',
    )?.toString();
    if (role == 'client') {
      Get.offAllNamed(Routes.clientHome, arguments: {'initialIndex': 2});
    } else if (role == 'partner') {
      Get.offAllNamed(Routes.partnerHome, arguments: {'initialIndex': 3});
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
      if (Get.currentRoute != Routes.partnerHome) {
        Get.until((route) => route.settings.name == Routes.partnerHome);
      }

      Get.find<PartnerBottomNavigationController>().setIndex(newShowTabIndex);
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
      if (Get.currentRoute != Routes.partnerHome) {
        Get.until((route) => route.settings.name == Routes.partnerHome);
      }

      Get.find<PartnerBottomNavigationController>().setIndex(
        partnerShowBottomTabIndex,
        setTab: showTabIndex,
      );
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

  static void openPartnerActiveBills() {
    HandleNotificationTap()._openPartnerShowScreen(showTabIndex: 1);
  }

  void _openClientOrdersScreen() {
    const clientOrdersTabIndex = 1;

    if (Get.isRegistered<ClientBottomNavigationController>()) {
      if (Get.currentRoute != Routes.clientHome) {
        Get.until((route) => route.settings.name == Routes.clientHome);
      }

      Get.find<ClientBottomNavigationController>().setIndex(
        clientOrdersTabIndex,
      );
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
