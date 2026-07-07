import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gta_app/firebase_options.dart';
import 'package:gta_app/src/commons/repository/shared_prefs_repo.dart';
import 'package:gta_app/src/res/endpoints.dart';
import 'package:http/http.dart' as http;

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

const _channelId = 'gta_high_importance_channel';
const _channelName = 'GTA Notifications';

final _localNotifications = FlutterLocalNotificationsPlugin();

const _androidChannel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
);

class FcmService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Background handler must be registered before any other setup
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Request permissions (no-op on Android < 13, shows dialog on iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: show banner/sound/badge even when app is in foreground
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    await _initLocalNotifications();

    // Foreground message handler — show local notification manually
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Get FCM token and persist
    try {
      final token = await messaging.getToken();
      if (token != null) {
        log('FCM Token obtained: $token', name: 'FCM');
        await SharedPrefsRepo().setFcmToken(token);
      }
    } catch (e) {
      log('Failed to get FCM token (likely running on iOS Simulator): $e', name: 'FCM');
    }

    // Re-upload token on rotation
    messaging.onTokenRefresh.listen((newToken) async {
      log('FCM Token refreshed: $newToken', name: 'FCM');
      await SharedPrefsRepo().setFcmToken(newToken);
      await _uploadIfAuthenticated(newToken);
    });
  }

  static Future<void> _initLocalNotifications() async {
    // Create the high-importance Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: notification.android?.imageUrl != null
          ? DrawableResourceAndroidBitmap(notification.android!.imageUrl!)
          : null,
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    log('Foreground notification shown: ${notification.title}', name: 'FCM');
  }

  /// Call right after a successful login (OTP or Google).
  static Future<void> uploadAfterLogin({
    required String authToken,
    required String userType,
  }) async {
    final fcmToken = await SharedPrefsRepo().getFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    await _upload(fcmToken: fcmToken, authToken: authToken, userType: userType);
  }

  static Future<void> _uploadIfAuthenticated(String fcmToken) async {
    final prefs = SharedPrefsRepo();
    final authToken = await prefs.getCookie();
    final userType = await prefs.getData('USER_TYPE');
    if (authToken == null || authToken.isEmpty || userType == null) return;
    await _upload(fcmToken: fcmToken, authToken: authToken, userType: userType);
  }

  static Future<void> _upload({
    required String fcmToken,
    required String authToken,
    required String userType,
  }) async {
    try {
      final url = userType == 'buyer'
          ? Endpoints.buyerFcmToken
          : Endpoints.sellerFcmToken;

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'token=$authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      log('FCM token upload [$userType] → ${response.statusCode}', name: 'FCM');
    } catch (e) {
      log('FCM token upload failed: $e', name: 'FCM');
    }
  }
}
