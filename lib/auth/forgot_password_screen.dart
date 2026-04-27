import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';

/// Sends a password-reset link to the user's email.
///
/// Push this screen from the "Forgot Password?" button in the login screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _loading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(_email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.friendlyError(e));
    } catch (_) {
      _showSnack('Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(padding: const EdgeInsets.all(24), child: _sent ? _successView() : _formView()),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.lock_reset, size: 60, color: Colors.purple),
          const SizedBox(height: 24),
          const Text(
            'Forgot your password?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we\'ll send you a reset link.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email.';
              if (!v.isValidEmail()) return 'Enter a valid email address.';
              return null;
            },
            onChanged: (v) => _email = v.trim(),
            decoration: textFormDecoration.copyWith(
              labelText: 'Email Address',
              hintText: 'Enter your registered email',
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Send Reset Link', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Reset link sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'Check your inbox at $_email and follow the link to reset your password.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Login', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
