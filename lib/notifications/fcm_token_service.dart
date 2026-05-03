

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<void> saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      print('🔑 FCM Token: $token');

      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': _getPlatform(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Token guardado en Firestore para uid: ${user.uid}');
    } catch (e) {
      print('❌ Error guardando token: $e');
    }
  }

  void listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 Token renovado: $newToken');
      await saveTokenToFirestore();
    });
  }

  Future<void> deleteTokenOnLogout() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .delete();

      await _messaging.deleteToken();
      print('🗑️ Token eliminado al cerrar sesión');
    } catch (e) {
      print('❌ Error eliminando token: $e');
    }
  }

  Future<void> followStore({required String storeId, required String storeName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final topic = _storeToTopic(storeId);
      await _messaging.subscribeToTopic(topic);
      print('🔔 Suscrito al topic: $topic');

      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('following')
          .doc(storeId)
          .set({
            'storeId': storeId,
            'storeName': storeName,
            'followedAt': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('suppliers').doc(storeId).update({
        'followersCount': FieldValue.increment(1),
      });

      print('✅ Siguiendo tienda: $storeName');
    } catch (e) {
      print('❌ Error al seguir tienda: $e');
    }
  }

  Future<void> unfollowStore({required String storeId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final topic = _storeToTopic(storeId);
      await _messaging.unsubscribeFromTopic(topic);
      print('🔕 Desuscrito del topic: $topic');

      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('following')
          .doc(storeId)
          .delete();

      await _firestore.collection('suppliers').doc(storeId).update({
        'followersCount': FieldValue.increment(-1),
      });

      print('✅ Dejaste de seguir la tienda: $storeId');
    } catch (e) {
      print('❌ Error al dejar de seguir tienda: $e');
    }
  }

  Future<bool> isFollowing(String storeId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('following')
        .doc(storeId)
        .get();

    return doc.exists;
  }

  Stream<bool> followingStream(String storeId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('following')
        .doc(storeId)
        .snapshots()
        .map((snap) => snap.exists);
  }

  String _storeToTopic(String storeId) {
    return 'store_${storeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
  }

  String _getPlatform() {
    try {
      return 'android'; 
    } catch (_) {
      return 'unknown';
    }
  }
}
