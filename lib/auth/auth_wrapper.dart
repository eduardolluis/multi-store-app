import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/main_screens/welcome.dart';

/// Drop this widget as the [home] of your [MaterialApp] (or as the first route).
///
/// It listens to [AuthService.authStateChanges] and routes accordingly:
///
///  • [User] signed in  →  [onAuthenticated] builder (welcome / home screen)
///  • No user           →  [unauthenticatedWidget] (welcome screen)
///
/// This replaces the old pattern of calling [FirebaseAuth.instance.currentUser]
/// inside [initState], which can crash or return stale data.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.onAuthenticated,
    required this.unauthenticatedWidget,
  });

  /// Called when a user is signed in. Receives the [User] and should return
  /// the correct home screen (customer vs supplier is determined by checking
  /// Firestore inside [WelcomeScreen] or a similar router widget).
  final Widget Function(User user) onAuthenticated;

  /// Shown when nobody is signed in.
  final Widget unauthenticatedWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.purple)),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // User is signed in — hand off to the authenticated widget.
          return onAuthenticated(user);
        }

        // Nobody signed in.
        return unauthenticatedWidget;
      },
    );
  }
}
