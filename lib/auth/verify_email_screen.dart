import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';

/// Show this screen right after sign-up (or any time the signed-in user
/// hasn't verified their email yet).
///
/// Usage:
/// ```dart
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(
///     builder: (_) => VerifyEmailScreen(nextRoute: '/customer_home'),
///   ),
/// );
/// ```
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.nextRoute});

  /// The named route to push once the email is verified.
  final String nextRoute;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // Poll Firebase every 3 seconds to see if the user clicked the link.
  Timer? _checkTimer;

  // Resend cool-down: 60 seconds.
  Timer? _resendTimer;
  int _resendCooldown = 0;
  bool _sending = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final verified = await AuthService.instance.checkEmailVerified();
      if (verified && mounted) {
        _checkTimer?.cancel();
        Navigator.pushReplacementNamed(context, widget.nextRoute);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _sending) return;

    setState(() => _sending = true);
    try {
      await AuthService.instance.sendVerificationEmail();
      _startCooldown();
      _showSnack('Verification email sent!');
    } catch (e) {
      _showSnack('Failed to send email. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final verified = await AuthService.instance.checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (verified) {
      Navigator.pushReplacementNamed(context, widget.nextRoute);
    } else {
      _showSnack('Email not verified yet. Check your inbox.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/welcome_screen');
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.purple),
            const SizedBox(height: 24),
            const Text(
              'Check your inbox',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to:\n$email\n\nOpen the link then come back.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // "I've Verified" button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checking ? null : _checkNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _checking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("I've Verified My Email", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),

            // Resend button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: (_resendCooldown > 0 || _sending) ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2),
                      )
                    : Text(
                        _resendCooldown > 0
                            ? 'Resend in ${_resendCooldown}s'
                            : 'Resend Verification Email',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "We're checking automatically every few seconds.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
