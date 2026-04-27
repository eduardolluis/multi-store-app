import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

const textColors = [
  Colors.yellowAccent,
  Colors.red,
  Colors.blueAccent,
  Colors.green,
  Colors.purple,
  Colors.teal,
];

const textStyle = TextStyle(fontSize: 45, fontWeight: FontWeight.bold, fontFamily: 'Acme');

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _processing = false;
  bool _googleLoading = false;

  CollectionReference customers = FirebaseFirestore.instance.collection('customers');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _controller.repeat();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isCustomer = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get()
        .then((d) => d.exists);

    if (!mounted) return;

    if (isCustomer) {
      Navigator.pushReplacementNamed(context, '/customer_home');
    } else {
      Navigator.pushReplacementNamed(context, '/supplier_home');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await AuthService.instance.signInWithGoogle();
      if (cred == null) return; // user cancelled

      if (!mounted) return;

      final uid = cred.user!.uid;

      // Check which collection this user belongs to
      final isCustomer = await AuthService.instance.userDocumentExists(
        uid: uid,
        collection: 'customers',
      );
      final isSupplier = await AuthService.instance.userDocumentExists(
        uid: uid,
        collection: 'suppliers',
      );

      if (!mounted) return;

      if (isSupplier) {
        Navigator.pushReplacementNamed(context, '/supplier_home');
      } else {
        // New user or existing customer — create customer doc if needed
        if (!isCustomer) {
          final user = cred.user!;
          await AuthService.instance.createCustomerDocument(
            uid: uid,
            name: user.displayName ?? 'Google User',
            email: user.email ?? '',
            profileImage: user.photoURL ?? '',
          );
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/customer_home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _guestSignIn() async {
    setState(() => _processing = true);
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final uid = credential.user?.uid ?? '';

      if (uid.isNotEmpty) {
        await customers.doc(uid).set({
          'name': '',
          'email': '',
          'profileImage': '',
          'phone': '',
          'address': '',
          'cid': uid,
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/customer_home');
      }
    } catch (e) {
      debugPrint('Guest sign-in error: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('images/inapp/bgimage.jpg'), fit: BoxFit.cover),
        ),
        constraints: const BoxConstraints.expand(),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  ColorizeAnimatedText('WELCOME', textStyle: textStyle, colors: textColors),
                  ColorizeAnimatedText('Duck Store', textStyle: textStyle, colors: textColors),
                ],
                isRepeatingAnimation: true,
                repeatForever: true,
              ),

              const SizedBox(
                height: 120,
                width: 200,
                child: Image(image: AssetImage('images/inapp/logo.jpg')),
              ),

              SizedBox(
                height: 80,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                    fontFamily: 'Acme',
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      RotateAnimatedText('Buy'),
                      RotateAnimatedText('Shop'),
                      RotateAnimatedText('Duck Store'),
                    ],
                    repeatForever: true,
                  ),
                ),
              ),

              // ── Suppliers row ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            bottomLeft: Radius.circular(50),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Suppliers only",
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 60,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: const BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            bottomLeft: Radius.circular(50),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedLogo(controller: _controller),
                            YellowButton(
                              label: 'Log In',
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(context, '/supplier_login'),
                              width: 0.25,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 9),
                              child: YellowButton(
                                label: 'Sign Up',
                                onPressed: () =>
                                    Navigator.pushReplacementNamed(context, '/supplier_signup'),
                                width: 0.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Customers row ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: const BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: YellowButton(
                            label: 'Log In',
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/customer_login'),
                            width: 0.25,
                          ),
                        ),
                        YellowButton(
                          label: 'Sign Up',
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/customer_signup'),
                          width: 0.25,
                        ),
                        AnimatedLogo(controller: _controller),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Social / Guest login ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white38.withOpacity(0.3)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Google sign-in
                      _googleLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            )
                          : GoogleFacebookLogin(
                              label: 'Google',
                              onPressed: _googleSignIn,
                              child: const Image(image: AssetImage('images/inapp/google.jpg')),
                            ),

                      // Facebook (placeholder)
                      GoogleFacebookLogin(
                        label: 'Facebook',
                        onPressed: () {},
                        child: const Image(image: AssetImage('images/inapp/facebook.jpg')),
                      ),

                      // Guest
                      _processing
                          ? const CircularProgressIndicator()
                          : GoogleFacebookLogin(
                              label: 'Guest',
                              onPressed: _guestSignIn,
                              child: const Icon(
                                Icons.person,
                                color: Colors.lightBlueAccent,
                                size: 55,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({super.key, required AnimationController controller})
    : _controller = controller;

  final AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (context, child) {
        return Transform.rotate(angle: _controller.value * 2 * pi, child: child);
      },
      child: const Image(image: AssetImage('images/inapp/logo.jpg')),
    );
  }
}

class GoogleFacebookLogin extends StatelessWidget {
  final String label;
  final Function() onPressed;
  final Widget child;
  const GoogleFacebookLogin({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onPressed,
        child: Column(
          children: [
            SizedBox(height: 50, width: 50, child: child),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
