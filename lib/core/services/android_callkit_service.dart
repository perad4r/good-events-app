import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/services/call_ringtone_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

class AndroidCallkitService {
  AndroidCallkitService._();

  static StreamSubscription<CallEvent?>? _eventSubscription;
  static final Set<String> _acceptedCallIds = <String>{};
  static const MethodChannel _nativeCallChannel = MethodChannel(
    'com.sukientot.app/call_audio',
  );

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_isAndroid || _eventSubscription != null) return;
    _nativeCallChannel.setMethodCallHandler((call) async {
      if (call.method == 'nativeCallAction') {
        try {
          await _handleNativeAction(call.arguments);
        } finally {
          await _nativeCallChannel.invokeMethod<void>('clearPendingCallAction');
        }
      }
    });
    _eventSubscription = FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      unawaited(_handleEvent(event));
    });
    final pending = await _nativeCallChannel.invokeMethod<Object?>(
      'consumePendingCallAction',
    );
    await _handleNativeAction(pending);
  }

  static Future<void> showIncomingCall(Map<String, dynamic> data) async {
    if (!_isAndroid) return;
    final callId = data['call_id']?.toString();
    if (callId == null || callId.isEmpty) return;
    final callerName = data['initiator_name']?.toString().trim();
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName == null || callerName.isEmpty
          ? 'Cuộc gọi đến'
          : callerName,
      appName: 'Sự kiện tốt',
      handle: data['thread_id']?.toString() ?? callId,
      type: 0,
      duration: 60000,
      extra: data,
      callingNotification: const NotificationParams(showNotification: false),
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        incomingCallNotificationChannelName: 'Cuộc gọi đến',
        missedCallNotificationChannelName: 'Cuộc gọi nhỡ',
        isShowCallID: false,
        isShowFullLockedScreen: false,
        isImportant: true,
        // Android displays a standard heads-up call notification. The app does
        // not request or use full-screen intent access.
        isFullScreen: false,
        textAccept: 'Trả lời',
        textDecline: 'Từ chối',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> markConnected(String callId) async {
    if (!_isAndroid) return;
    try {
      await FlutterCallkitIncoming.setCallConnected(callId);
    } on PlatformException catch (error) {
      logger.w(
        '[AndroidCallkit] Unable to mark Telecom call connected: ${error.code}',
      );
    }
    try {
      await _nativeCallChannel.invokeMethod<void>(
        'startOngoingCall',
        <String, String>{'call_id': callId},
      );
    } on PlatformException catch (error) {
      logger.w(
        '[AndroidCallkit] Unable to start ongoing call service: ${error.code}',
      );
    } on MissingPluginException {
      logger.w('[AndroidCallkit] Native ongoing call service is unavailable.');
    }
  }

  static Future<void> hideIncomingNotification(String callId) async {
    if (!_isAndroid) return;
    try {
      await FlutterCallkitIncoming.hideCallkitIncoming(
        CallKitParams(id: callId, isAccepted: true),
      );
    } on PlatformException catch (error) {
      logger.w(
        '[AndroidCallkit] Unable to hide incoming notification: ${error.code}',
      );
    }
  }

  static Future<void> endCall(String callId) async {
    if (!_isAndroid) return;
    _acceptedCallIds.remove(callId);
    await CallRingtoneService.stop();
    try {
      await _nativeCallChannel.invokeMethod<void>('stopOngoingCall');
    } on PlatformException catch (error) {
      logger.w(
        '[AndroidCallkit] Unable to stop ongoing call service: ${error.code}',
      );
    } on MissingPluginException {
      logger.w('[AndroidCallkit] Native ongoing call service is unavailable.');
    }
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } on PlatformException catch (error) {
      logger.w('[AndroidCallkit] Unable to end Telecom call: ${error.code}');
    }
  }

  static Future<void> handleCallEnded(Map<String, dynamic> data) async {
    final callId = data['call_id']?.toString();
    if (callId == null || callId.isEmpty) return;
    await endCall(callId);
    if (Get.isRegistered<CallCoordinator>()) {
      await Get.find<CallCoordinator>().handleCallEndedSignal(callId);
    }
  }

  static Future<void> _handleEvent(CallEvent event) async {
    if (!Get.isRegistered<CallCoordinator>()) {
      if (event is CallEventActionCallDecline) {
        final data = event.callKitParams.extra;
        if (data != null) await _declineWithoutCoordinator(data);
      }
      return;
    }
    final coordinator = Get.find<CallCoordinator>();
    if (event is CallEventActionCallAccept) {
      final data = event.callKitParams.extra;
      if (data != null) await _acceptCall(data, coordinator);
      return;
    }
    if (event is CallEventActionCallDecline) {
      final data = event.callKitParams.extra;
      if (data != null) {
        await coordinator.handleIncomingNotification(data);
        await coordinator.decline();
      }
      return;
    }
    if (event is CallEventActionCallTimeout) {
      if (coordinator.activeCall.value != null) await coordinator.decline();
      return;
    }
    if (event is CallEventActionCallEnded) {
      if (coordinator.localState.value == LocalCallState.connected ||
          coordinator.localState.value == LocalCallState.reconnecting) {
        await coordinator.leave();
      } else {
        final data = event.callKitParams.extra;
        if (data != null) {
          await coordinator.handleIncomingNotification(data);
          await coordinator.decline();
        }
      }
    }
  }

  static Future<void> _handleNativeAction(Object? value) async {
    if (value is! Map) return;
    final action = value['action']?.toString();
    final rawData = value['data'];
    if (rawData is! Map) return;
    final data = rawData.map((key, value) => MapEntry(key.toString(), value));
    if (!Get.isRegistered<CallCoordinator>()) {
      if (action == 'decline') await _declineWithoutCoordinator(data);
      return;
    }
    final coordinator = Get.find<CallCoordinator>();
    if (action == 'accept') {
      await _acceptCall(data, coordinator);
    } else if (action == 'decline') {
      await coordinator.handleIncomingNotification(data);
      await coordinator.decline();
    } else if (action == 'end') {
      await coordinator.leave();
    }
  }

  static Future<void> _declineWithoutCoordinator(
    Map<String, dynamic> data,
  ) async {
    final callId = data['call_id']?.toString();
    if (callId == null || callId.isEmpty) return;
    try {
      await ApiService().dio.post<void>(AppUrl.declineCall(callId));
      logger.i('[AndroidCallkit] Native decline sent for call $callId.');
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404 || statusCode == 409) {
        logger.i('[AndroidCallkit] Call $callId was already unavailable.');
        return;
      }
      logger.e(
        '[AndroidCallkit] Native decline failed for call $callId.',
        error: error,
      );
    }
  }

  static Future<void> _acceptCall(
    Map<String, dynamic> data,
    CallCoordinator coordinator,
  ) async {
    final callId = data['call_id']?.toString();
    if (callId == null || callId.isEmpty || !_acceptedCallIds.add(callId)) {
      return;
    }
    await coordinator.handleIncomingNotification(data);
    await coordinator.joinActiveCall();
  }
}
