import 'dart:convert';

import './handle_notification_code.dart';
import './handle_notification_tap.dart';
import './handle_notification_terminated_tap.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i('[FCM] Background message received: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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
              decoded.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
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
      _syncTokenToBackend(newToken);
    });

    // 5. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      final data = message.data;
      logger.i(
        '[FCM] Foreground message — title: $title | body: $body | data: $data',
      );

      NotificationHandler.handleMessage(data);

      if (!kIsWeb) {
        _showLocalNotification(message);
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
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      logger.e('[FCM] Failed to retrieve token', error: e);
    }
  }

  static Future<void> _syncTokenToBackend(String token) async {
    // Only sync when the user is authenticated
    final authToken = StorageService.readData(key: LocalStorageKeys.token);
    if (authToken == null) {
      logger.i('[FCM] Skipping backend sync — user not authenticated.');
      return;
    }

    try {
      final response = await _apiService.dio.post(
        AppUrl.updateFcmToken,
        data: {'fcm_token': token},
      );
      if (response.statusCode == 200) {
        logger.i('[FCM] Token synced to backend successfully.');
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
      await _syncTokenToBackend(token);
    } else {
      await _fetchAndSaveToken();
    }
  }

  /// Returns the persisted FCM token (may be null before init completes).
  static String? getToken() {
    return StorageService.readData(key: LocalStorageKeys.fcmToken) as String?;
  }
}
