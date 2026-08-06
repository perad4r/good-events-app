import 'dart:async';
import 'dart:convert';
import 'dart:math';

import './handle_notification_code.dart';
import './handle_notification_tap.dart';
import './handle_notification_terminated_tap.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/services/android_callkit_service.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';
import 'package:sukientotapp/firebase_options.dart';

const AndroidNotificationChannel _incomingCallChannel =
    AndroidNotificationChannel(
      'incoming_calls',
      'Cuộc gọi đến',
      description: 'Thông báo cuộc gọi âm thanh đến.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

final FlutterLocalNotificationsPlugin _backgroundNotifications =
    FlutterLocalNotificationsPlugin();

int _incomingCallNotificationId(String callId) {
  var hash = 0x811C9DC5;
  for (final codeUnit in callId.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AndroidCallkitService.showIncomingCall(data);
    return;
  }
  final callId = data['call_id']?.toString();
  if (callId == null || callId.isEmpty) return;

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    iOS: DarwinInitializationSettings(),
  );
  await _backgroundNotifications.initialize(settings: initializationSettings);
  await _backgroundNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_incomingCallChannel);

  final callerName = data['initiator_name']?.toString() ?? 'Có người';
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _incomingCallChannel.id,
      _incomingCallChannel.name,
      channelDescription: _incomingCallChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      // Android FLAG_INSISTENT: repeat sound until the call notification is
      // cancelled by accept, decline, end, or timeout.
      additionalFlags: Int32List.fromList(<int>[4]),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );
  await _backgroundNotifications.show(
    id: _incomingCallNotificationId(callId),
    title: 'Cuộc gọi âm thanh đến',
    body: '$callerName đang gọi cho bạn',
    notificationDetails: details,
    payload: jsonEncode(data),
  );
}

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  logger.i('[FCM] Background message received: ${message.messageId}');
  final type = message.data['type']?.toString();
  if (type == 'incoming_call') {
    await _showIncomingCallNotification(message.data);
  } else if (type == 'call_ended') {
    final callId = message.data['call_id']?.toString();
    if (callId != null && callId.isNotEmpty) {
      await AndroidCallkitService.endCall(callId);
    }
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const MethodChannel _pushKitChannel = MethodChannel(
    'com.sukientot.app/pushkit',
  );

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            HandleNotificationTap.handleTap(decoded);
          } else if (decoded is Map) {
            HandleNotificationTap.handleTap(
              decoded.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        } catch (e) {
          logger.e(
            '[FCM] Failed to decode local notification payload',
            error: e,
          );
        }
      },
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_incomingCallChannel);
    final fullScreenGranted = await androidNotifications
        ?.requestFullScreenIntentPermission();
    logger.i('[FCM] Full-screen intent permission granted: $fullScreenGranted');

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(launchPayload);
        if (decoded is Map) {
          HandleNotificationTerminatedTap.handleTap(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (error) {
        logger.w('[FCM] Invalid terminated local notification payload.');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> init() async {
    if (_initialized) {
      logger.i('[FCM] Already initialized, skipping.');
      return;
    }
    _initialized = true;

    await _initializePushKitBridge();
    await AndroidCallkitService.initialize();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    logger.i('[FCM] Permission status: ${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final isGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isGranted) {
      logger.w('[FCM] Notification permission not granted.');
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      logger.i('[FCM] APNs token: $apnsToken');
      if (apnsToken == null) {
        logger.w('[FCM] APNs token is null - iOS notifications may not work.');
      }
    }

    await _fetchAndSaveToken();

    // 4. Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) {
      StorageService.writeStringData(
        key: LocalStorageKeys.fcmToken,
        value: newToken,
      );
      logger.i('[FCM] Token refreshed: $newToken');
      _syncDeviceToBackend(fcmToken: newToken);
    });

    // 5. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      final data = message.data;
      logger.i(
        '[FCM] Foreground message — title: $title | body: $body | data: $data',
      );

      final type = data['type']?.toString();
      final isAndroidIncomingCall =
          type == 'incoming_call' &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android;
      if (isAndroidIncomingCall) {
        unawaited(AndroidCallkitService.showIncomingCall(data));
      } else if (type == 'call_ended' && !kIsWeb) {
        unawaited(AndroidCallkitService.handleCallEnded(data));
      } else if (!kIsWeb) {
        NotificationHandler.handleMessage(data);
        _showLocalNotification(message);
      } else {
        NotificationHandler.handleMessage(data);
      }
    });

    // 6. App opened from a background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      final data = message.data;
      logger.i(
        '[FCM] Opened from background: $title | body: $body | data: $data',
      );
      HandleNotificationTap.handleTap(data);
    });

    // 7. App launched from a terminated-state notification tap
    final initialMessage = await _messaging.getInitialMessage();
    final title = initialMessage?.notification?.title;
    final body = initialMessage?.notification?.body;
    final data = initialMessage?.data;
    if (initialMessage != null) {
      logger.i(
        '[FCM] App launched from terminated state: $title | body: $body | data: $data',
      );
      HandleNotificationTerminatedTap.handleTap(data);
    }
  }

  static Future<void> _fetchAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.fcmToken,
          value: token,
        );
        logger.i('[FCM] Registration token: $token');
        await _syncDeviceToBackend(fcmToken: token);
      }
    } catch (e) {
      logger.e('[FCM] Failed to retrieve token', error: e);
    }
  }

  static Future<void> _syncDeviceToBackend({String? fcmToken}) async {
    // Only sync when the user is authenticated
    final authToken = StorageService.readData(key: LocalStorageKeys.token);
    if (authToken == null) {
      logger.i('[FCM] Skipping backend sync — user not authenticated.');
      return;
    }

    try {
      final deviceId = _getOrCreateDeviceId();
      final resolvedFcmToken =
          fcmToken ??
          StorageService.readData(key: LocalStorageKeys.fcmToken) as String?;
      if (resolvedFcmToken == null || resolvedFcmToken.isEmpty) return;
      final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final voipToken = isIos
          ? StorageService.readData(key: LocalStorageKeys.voipToken) as String?
          : null;
      if (isIos && (voipToken == null || voipToken.isEmpty)) {
        logger.i('[PushDevice] Waiting for PushKit token before iOS sync.');
        return;
      }
      final response = await _apiService.dio.post(
        AppUrl.pushDevices,
        data: {
          'device_id': deviceId,
          'platform': isIos ? 'ios' : 'android',
          'fcm_token': resolvedFcmToken,
          if (isIos) 'voip_token': voipToken,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('[PushDevice] Device registration synced successfully.');
      }
    } on DioException catch (e) {
      logger.e('[FCM] Failed to sync token to backend', error: e.message);
    } catch (e) {
      logger.e('[FCM] Failed to sync token to backend', error: e);
    }
  }

  /// Syncs the existing FCM token to backend — call this after user logs in.
  static Future<void> syncTokenAfterLogin() async {
    final token =
        StorageService.readData(key: LocalStorageKeys.fcmToken) as String?;
    if (token != null) {
      await _syncDeviceToBackend(fcmToken: token);
    } else {
      await _fetchAndSaveToken();
    }
  }

  /// Returns the persisted FCM token (may be null before init completes).
  static String? getToken() {
    return StorageService.readData(key: LocalStorageKeys.fcmToken) as String?;
  }

  static Future<void> cancelIncomingCall(
    String callId, {
    bool accepted = false,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (accepted) {
        await AndroidCallkitService.hideIncomingNotification(callId);
        return;
      }
      await AndroidCallkitService.endCall(callId);
      return;
    }
    await _localNotifications.cancel(id: _incomingCallNotificationId(callId));
  }

  static Future<void> markIncomingCallConnected(String callId) async {
    await AndroidCallkitService.markConnected(callId);
  }

  static Future<void> unregisterDeviceBeforeLogout() async {
    final authToken = StorageService.readData(key: LocalStorageKeys.token);
    final deviceId =
        StorageService.readData(key: LocalStorageKeys.pushDeviceId) as String?;
    if (authToken == null || deviceId == null || deviceId.isEmpty) return;
    try {
      await _apiService.dio.delete(AppUrl.pushDevice(deviceId));
      logger.i('[PushDevice] Device unregistered successfully.');
    } on DioException catch (error) {
      logger.w(
        '[PushDevice] Unable to unregister device: ${error.response?.statusCode}',
      );
    }
  }

  static Future<void> _initializePushKitBridge() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _pushKitChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'voipTokenUpdated':
          final token = call.arguments?.toString();
          if (token == null || token.isEmpty) return;
          StorageService.writeStringData(
            key: LocalStorageKeys.voipToken,
            value: token,
          );
          await _syncDeviceToBackend();
          return;
        case 'voipCallAnswered':
          final data = _stringKeyedMap(call.arguments);
          if (data == null || !Get.isRegistered<CallCoordinator>()) return;
          final coordinator = Get.find<CallCoordinator>();
          await coordinator.handleIncomingNotification(data);
          await coordinator.joinActiveCall();
          return;
        case 'voipCallEnded':
          final data = _stringKeyedMap(call.arguments);
          if (data == null || !Get.isRegistered<CallCoordinator>()) return;
          final coordinator = Get.find<CallCoordinator>();
          await coordinator.handleIncomingNotification(data);
          await coordinator.decline();
          return;
      }
    });
    try {
      final token = await _pushKitChannel.invokeMethod<String>('getVoipToken');
      if (token != null && token.isNotEmpty) {
        StorageService.writeStringData(
          key: LocalStorageKeys.voipToken,
          value: token,
        );
      }
    } on PlatformException catch (error) {
      logger.w('[PushKit] Unable to read VoIP token: ${error.code}');
    }
  }

  static Map<String, dynamic>? _stringKeyedMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _getOrCreateDeviceId() {
    final existing =
        StorageService.readData(key: LocalStorageKeys.pushDeviceId) as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final raw = bytes.map(hex).join();
    final deviceId =
        '${raw.substring(0, 8)}-${raw.substring(8, 12)}-'
        '${raw.substring(12, 16)}-${raw.substring(16, 20)}-'
        '${raw.substring(20)}';
    StorageService.writeStringData(
      key: LocalStorageKeys.pushDeviceId,
      value: deviceId,
    );
    return deviceId;
  }
}
