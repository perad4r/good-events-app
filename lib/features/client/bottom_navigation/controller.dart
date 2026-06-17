import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/features/client/home/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';

class ClientBottomNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  var isReverse = false.obs;

  static const _pusherEventName = 'SendMessage';
  String? _userChannel;
  DateTime? _lastHomeSummaryRefreshAt;

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
    if (userId == null) return;
    final channelName = 'private-user-messages.$userId';
    await PusherService.subscribe(
      channelName: channelName,
      eventName: _pusherEventName,
      onEvent: _onUserChannelMessage,
    );
    _userChannel = channelName;
    logger.i('[ClientBottomNav] [Pusher] Subscribed to $channelName');
  }

  Future<void> _unsubscribeUserChannel() async {
    if (_userChannel == null) return;
    await PusherService.unsubscribe(_userChannel!);
    logger.i('[ClientBottomNav] [Pusher] Unsubscribed from $_userChannel');
    _userChannel = null;
  }

  void _onUserChannelMessage(PusherEvent event) {
    if (Get.isRegistered<MessageController>()) {
      Get.find<MessageController>().onUserChannelEvent(event);
    }
  }

  void setIndex(int index) {
    final prev = currentIndex.value;
    isReverse.value = index < currentIndex.value;
    currentIndex.value = index;

    // tab switches can keep old/new pages alive briefly due to animated transitions.
    // refresh home summary on focus, but throttle to avoid spamming API on fast taps.
    if (index == 0 && prev != 0 && Get.isRegistered<ClientHomeController>()) {
      final now = DateTime.now();
      final last = _lastHomeSummaryRefreshAt;
      if (last == null || now.difference(last) > const Duration(seconds: 2)) {
        _lastHomeSummaryRefreshAt = now;
        Future.microtask(() => Get.find<ClientHomeController>().fetchSummary());
      }
    }
  }

  void _setInitialIndexFromArguments() {
    final args = Get.arguments;
    int? initialIndex;

    if (args is Map && args['initialIndex'] is int) {
      initialIndex = args['initialIndex'] as int;
    } else {
      final pendingIndex = StorageService.readData(
        key: LocalStorageKeys.pendingClientTabIndex,
      )?.toString();
      if (pendingIndex != null) {
        StorageService.removeData(key: LocalStorageKeys.pendingClientTabIndex);
        initialIndex = int.tryParse(pendingIndex);
      }
    }

    if (initialIndex == null) return;
    if (initialIndex < 0 || initialIndex > 3) return;

    currentIndex.value = initialIndex;
  }
}
