
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📩 [BACKGROUND] Mensaje recibido');
  print('ID: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  final data = message.data;

  final String? type = data['type'];
  final String? orderId = data['orderId'];
  final String? storeId = data['storeId'];
  final String? customerId = data['customerId'];
  final String? supplierId = data['supplierId'];

  try {
    await FirebaseFirestore.instance.collection('notification_logs').add({
      'messageId': message.messageId,
      'type': type ?? 'general',
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': data,
      'orderId': orderId,
      'storeId': storeId,
      'customerId': customerId,
      'supplierId': supplierId,
      'receivedAt': FieldValue.serverTimestamp(),
      'state': 'background',
    });

    if (customerId != null && customerId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .collection('notifications')
          .add({
            'messageId': message.messageId,
            'type': type ?? 'general',
            'title': message.notification?.title ?? 'Multi Store',
            'body': message.notification?.body ?? '',
            'data': data,
            'orderId': orderId,
            'storeId': storeId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }

    if (supplierId != null && supplierId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('suppliers')
          .doc(supplierId)
          .collection('notifications')
          .add({
            'messageId': message.messageId,
            'type': type ?? 'general',
            'title': message.notification?.title ?? 'Multi Store',
            'body': message.notification?.body ?? '',
            'data': data,
            'orderId': orderId,
            'customerId': customerId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }

    if (orderId != null && orderId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'lastNotificationAt': FieldValue.serverTimestamp(),
        'lastNotificationType': type ?? 'general',
      }, SetOptions(merge: true));
    }

    print('✅ Notificación procesada en background');
  } catch (e) {
    print('❌ Error procesando notificación background: $e');
  }
}
