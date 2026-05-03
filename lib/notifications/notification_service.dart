import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _channelId = 'duck_store_high_importance';
  static const String _channelName = 'Duck Store Notifications';
  static const String _channelDescription = 'Order updates, offers, and stores you follow';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _createAndroidChannel();
    await _initLocalNotifications();
    await _requestPermissions();

    _listenForeground();
    _handleNotificationOpenedApp();
    await _handleInitialMessage();
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalTap,
      onDidReceiveBackgroundNotificationResponse: _onLocalBackgroundTap,
    );
  }

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 [FOREGROUND] ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _showHeadsUp(
          title: notification.title ?? 'Duck Store',
          body: notification.body ?? '',
          payload: message.data['route'],
        );
      }
    });
  }

  void _handleNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 [BG TAP] route=${message.data['route']}');
      _navigateTo(message.data['route']);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('🚀 [TERMINATED TAP] route=${initial.data['route']}');
      await Future.delayed(const Duration(milliseconds: 800));
      _navigateTo(initial.data['route']);
    }
  }

  Future<void> _showHeadsUp({required String title, required String body, String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _onLocalTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      _navigateTo(response.payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onLocalBackgroundTap(NotificationResponse response) {}

  void _navigateTo(String? route) {
    if (route == null || route.isEmpty) return;
    navigatorKey.currentState?.pushNamed(route);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) => _showHeadsUp(title: title, body: body, payload: payload);

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
