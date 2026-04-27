// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/auth/verify_email_screen.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class CustomerSignup extends StatefulWidget {
  const CustomerSignup({super.key});

  @override
  State<CustomerSignup> createState() => _CustomerSignupState();
}

class _CustomerSignupState extends State<CustomerSignup> {
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _processing = false;

  // Live password strength score (0–4)
  int _strengthScore = 0;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );
      if (picked != null) setState(() => _imageFile = picked);
    } catch (e) {
      print('Image pick error: $e');
    }
  }



  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Please fill all fields correctly.');
      return;
    }
    if (_imageFile == null) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Please pick a profile photo.');
      return;
    }

    setState(() => _processing = true);

    try {
  
      final cred = await AuthService.instance.createAccountWithEmail(
        email: _email,
        password: _password,
      );

      final uid = cred.user!.uid;


      final profileImageUrl = await AuthService.instance.uploadProfileImage(
        uid: uid,
        file: File(_imageFile!.path),
      );


      await AuthService.instance.createCustomerDocument(
        uid: uid,
        name: _name,
        email: _email,
        profileImage: profileImageUrl,
      );


      if (!mounted) return;
      _formKey.currentState!.reset();
      setState(() => _imageFile = null);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen(nextRoute: '/customer_home')),
      );
    } on FirebaseAuthException catch (e) {
      MyMessageHandler.showSnackBar(_scaffoldKey, AuthService.friendlyError(e));
    } catch (e) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Sign-up failed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              reverse: true,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthHeaderLabel(headerLabel: 'Sign Up'),

                    // ── Profile image picker ──────────────────────────────
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.purpleAccent,
                            backgroundImage: _imageFile == null
                                ? null
                                : FileImage(File(_imageFile!.path)),
                            child: _imageFile == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        Column(
                          children: [
                            _imagePickerButton(
                              icon: Icons.camera_alt,
                              onPressed: () => _pickImage(ImageSource.camera),
                              top: true,
                            ),
                            const SizedBox(height: 6),
                            _imagePickerButton(
                              icon: Icons.photo,
                              onPressed: () => _pickImage(ImageSource.gallery),
                              top: false,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Name ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your full name.' : null,
                        onChanged: (v) => _name = v.trim(),
                        decoration: textFormDecoration.copyWith(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.purple),
                        ),
                      ),
                    ),

                    // ── Email ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email address.';
                          }
                          if (!v.isValidEmail()) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onChanged: (v) => _email = v.trim(),
                        decoration: textFormDecoration.copyWith(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.purple),
                        ),
                      ),
                    ),

                    // ── Password ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            obscureText: !_passwordVisible,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter a password.';
                              }
                              return AuthService.validatePasswordStrength(v);
                            },
                            onChanged: (v) {
                              _password = v;
                              setState(() {
                                _strengthScore = AuthService.passwordStrengthScore(v);
                              });
                            },
                            decoration: textFormDecoration.copyWith(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _passwordVisible = !_passwordVisible),
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ),

                          // Strength indicator
                          if (_password.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _StrengthBar(score: _strengthScore),
                          ],
                        ],
                      ),
                    ),

                    // ── Confirm password ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        obscureText: !_confirmVisible,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (v != _password) return 'Passwords do not match.';
                          return null;
                        },
                        onChanged: (v) => _confirmPassword = v,
                        decoration: textFormDecoration.copyWith(
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
                            icon: Icon(
                              _confirmVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                    ),

                    HaveAccount(
                      haveAccount: 'Already have an account? ',
                      actionLabel: 'Log In',
                      onPressed: () => Navigator.pushReplacementNamed(context, '/customer_login'),
                    ),

                    const SizedBox(height: 8),

                    _processing
                        ? const CircularProgressIndicator(color: Colors.purple)
                        : AuthButton(mainButtonLabel: 'Sign Up', onPressed: _signUp),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePickerButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool top,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(top ? 15 : 0),
          topRight: Radius.circular(top ? 15 : 0),
          bottomLeft: Radius.circular(top ? 0 : 15),
          bottomRight: Radius.circular(top ? 0 : 15),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}


class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.score});
  final int score;

  Color get _color {
    if (score <= 1) return Colors.red;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.yellow.shade700;
    return Colors.green;
  }

  String get _label {
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: score / 4,
                color: _color,
                backgroundColor: Colors.grey.shade200,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Min 8 chars · uppercase · lowercase · digit · special char',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
