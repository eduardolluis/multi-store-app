import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> reloadUser() async => await _auth.currentUser?.reload();

  Future<UserCredential> signInWithEmail({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.sendEmailVerification();
    return cred;
  }

  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    await reloadUser();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'No signed-in user found.');
    }

    final cred = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
    await user.reauthenticateWithCredential(cred);

    final strengthError = validatePasswordStrength(newPassword);
    if (strengthError != null) {
      throw FirebaseAuthException(code: 'weak-password', message: strengthError);
    }

    await user.updatePassword(newPassword);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<DocumentSnapshot?> getUserDocument({
    required String uid,
    required String collection,
  }) async {
    final doc = await _db.collection(collection).doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<bool> userDocumentExists({required String uid, required String collection}) async {
    final doc = await _db.collection(collection).doc(uid).get();
    return doc.exists;
  }

  Future<void> createCustomerDocument({
    required String uid,
    required String name,
    required String email,
    required String profileImage,
  }) {
    return _db.collection('customers').doc(uid).set({
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'phone': '',
      'address': '',
      'cid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createSupplierDocument({
    required String uid,
    required String name,
    required String email,
    required String profileImage,
    required String storeName,
    required String storeDescription,
    required String storeAddress,
    required String storeEmail,
    required String storePhone,
  }) {
    return _db.collection('suppliers').doc(uid).set({
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'phone': storePhone,
      'storeName': storeName,
      'storeLogo': profileImage,
      'coverImage': '',
      'storeDescription': storeDescription,
      'storeAddress': storeAddress,
      'storeEmail': storeEmail,
      'storePhone': storePhone,
      'cid': uid,
      'sid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<String> uploadProfileImage({required String uid, required File file}) async {
    final supabase = Supabase.instance.client;
    final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('images').upload(fileName, file);
    return supabase.storage.from('images').getPublicUrl(fileName);
  }


  static String? validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit.';
    }
    if (!password.contains(RegExp(r'[!@#\$&*~^%+=?]'))) {
      return 'Password must contain at least one special character (!@#\$&*~^%+=?).';
    }
    return null;
  }

  static int passwordStrengthScore(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$&*~^%+=?]'))) score++;
    return score;
  }

  
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return e.message ?? 'Password is too weak.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'no-current-user':
        return e.message ?? 'No signed-in user.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
