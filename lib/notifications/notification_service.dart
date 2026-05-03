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

  static const String _channelId = 'multi_store_high_importance';
  static const String _channelName = 'Multi Store Notifications';
  static const String _channelDescription =
      'Notificaciones de pedidos, ofertas y tiendas que sigues';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    await _createAndroidChannel();
    await _initializeLocalNotifications();
    await _requestPermissions();

    _listenForegroundMessages();
    _handleNotificationOpenedApp();
    await _handleInitialMessage();
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    print('✅ Canal de notificaciones creado: $_channelName');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones: CONCEDIDO');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Permiso de notificaciones: PROVISIONAL');
    } else {
      print('❌ Permiso de notificaciones: DENEGADO');
    }
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 [FOREGROUND] Mensaje recibido');
      print('Título: ${message.notification?.title}');
      print('Cuerpo: ${message.notification?.body}');
      print('Data: ${message.data}');

      final notification = message.notification;

      if (notification != null) {
        _showHeadsUpNotification(
          title: notification.title ?? 'Multi Store',
          body: notification.body ?? '',
          payload: message.data['route'],
        );
      }
    });
  }

  Future<void> _showHeadsUpNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _handleNotificationOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 [BACKGROUND TAP] Usuario tocó notificación');
      _navigateFromMessage(message.data);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 [TERMINATED TAP] App abierta desde notificación');

      Future.delayed(const Duration(seconds: 1), () {
        _navigateFromMessage(initialMessage.data);
      });
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;

    if (payload != null && payload.isNotEmpty) {
      print('👆 [FOREGROUND TAP] Navegando a: $payload');
      navigatorKey.currentState?.pushNamed(payload);
    }
  }

  void _navigateFromMessage(Map<String, dynamic> data) {
    final route = data['route'];

    if (route != null && route.toString().isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route.toString());
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showHeadsUpNotification(title: title, body: body, payload: payload);
  }
}
