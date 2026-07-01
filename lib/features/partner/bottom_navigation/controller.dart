import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';

class PartnerBottomNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  var isReverse = false.obs;

  String? _userChannel;

  @override
  void onInit() {
    super.onInit();
    _setInitialIndexFromArguments();
    _subscribeToUserChannel();
  }

  @override
  void onClose() {
    _unsubscribeUserChannel();
    super.onClose();
  }

  Future<void> _subscribeToUserChannel() async {
    final userId =
        StorageService.readMapData(key: LocalStorageKeys.user, mapKey: 'id')
            as int?;
    if (userId == null) {
      logger.w(
        '[PartnerBottomNav] [UserChannel] userId is null, skipping subscribe',
      );
      return;
    }
    final channelName = 'private-user-messages.$userId';
    await PusherService.subscribe(
      channelName: channelName,
      eventName: 'SendMessage',
      onEvent: _onUserChannelMessage,
    );
    _userChannel = channelName;
    logger.i('[PartnerBottomNav] [Pusher] Subscribed to $channelName');
  }

  Future<void> _unsubscribeUserChannel() async {
    if (_userChannel == null) return;
    await PusherService.unsubscribe(_userChannel!);
    logger.i('[PartnerBottomNav] [Pusher] Unsubscribed from $_userChannel');
    _userChannel = null;
  }

  void _onUserChannelMessage(PusherEvent event) {
    logger.i(
      '[PartnerBottomNav] [UserChannel] Raw event → name="${event.eventName}" data=${event.data}',
    );
    if (!Get.isRegistered<MessageController>()) {
      logger.w(
        '[PartnerBottomNav] [UserChannel] MessageController not registered, skipping',
      );
      return;
    }
    Get.find<MessageController>().onUserChannelEvent(event);
  }

  void setIndex(int index, {int? setTab}) {
    isReverse.value = index < currentIndex.value;
    currentIndex.value = index;

    if (index == 1 && setTab != null) {
      if (Get.isRegistered<ShowController>()) {
        final showController = Get.find<ShowController>();
        showController.switchTab(setTab);
      } else {}
    }
  }

  void _setInitialIndexFromArguments() {
    final args = Get.arguments;
    int? initialIndex;
    int? initialShowTabIndex;
    String? pendingRoute;

    if (args is Map) {
      if (args['initialIndex'] is int) {
        initialIndex = args['initialIndex'] as int;
      }
      if (args['initialShowTabIndex'] is int) {
        initialShowTabIndex = args['initialShowTabIndex'] as int;
      }
    } else {
      final pendingIndex = StorageService.readData(
        key: LocalStorageKeys.pendingPartnerTabIndex,
      )?.toString();
      final pendingShowTabIndex = StorageService.readData(
        key: LocalStorageKeys.pendingPartnerShowTabIndex,
      )?.toString();
      pendingRoute = StorageService.readData(
        key: LocalStorageKeys.pendingPartnerRoute,
      )?.toString();

      if (pendingIndex != null) {
        StorageService.removeData(key: LocalStorageKeys.pendingPartnerTabIndex);
        StorageService.removeData(
          key: LocalStorageKeys.pendingPartnerShowTabIndex,
        );
        initialIndex = int.tryParse(pendingIndex);
        initialShowTabIndex = int.tryParse(pendingShowTabIndex ?? '');
      }

      if (pendingRoute != null) {
        StorageService.removeData(key: LocalStorageKeys.pendingPartnerRoute);
      }
    }

    if (pendingRoute == LocalStorageKeys.pendingPartnerRouteReviews) {
      Future.microtask(() => Get.toNamed(Routes.partnerReviews));
    }

    if (initialIndex == null) return;
    if (initialIndex < 0 || initialIndex > 4) return;

    currentIndex.value = initialIndex;

    if (initialIndex == 1 &&
        initialShowTabIndex != null &&
        initialShowTabIndex >= 0 &&
        initialShowTabIndex <= 2) {
      Future.microtask(() {
        if (Get.isRegistered<ShowController>()) {
          Get.find<ShowController>().switchTab(initialShowTabIndex!);
        }
      });
    }
  }
}
