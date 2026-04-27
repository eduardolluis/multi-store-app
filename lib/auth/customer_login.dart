import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/auth/forgot_password_screen.dart';
import 'package:multi_store_app/auth/verify_email_screen.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class CustomerLogin extends StatefulWidget {
  const CustomerLogin({super.key});

  @override
  State<CustomerLogin> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLogin> {
  String _email = '';
  String _password = '';

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  bool _passwordVisible = false;
  bool _loading = false;
  bool _googleLoading = false;

  // ── Email / Password login ────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await AuthService.instance.signInWithEmail(email: _email, password: _password);

      final verified = await AuthService.instance.checkEmailVerified();
      if (!mounted) return;

      if (!verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen(nextRoute: '/customer_home')),
        );
        return;
      }

      _formKey.currentState!.reset();
      Navigator.pushReplacementNamed(context, '/customer_home');
    } on FirebaseAuthException catch (e) {
      MyMessageHandler.showSnackBar(_scaffoldKey, AuthService.friendlyError(e));
    } catch (_) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Login failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<void> _googleLogin() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await AuthService.instance.signInWithGoogle();
      if (cred == null) return;
      if (!mounted) return;

      final uid = cred.user!.uid;
      final docExists = await AuthService.instance.userDocumentExists(
        uid: uid,
        collection: 'customers',
      );

      if (!docExists) {
        final user = cred.user!;
        await AuthService.instance.createCustomerDocument(
          uid: uid,
          name: user.displayName ?? 'Google User',
          email: user.email ?? '',
          profileImage: user.photoURL ?? '',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/customer_home');
    } on FirebaseAuthException catch (e) {
      MyMessageHandler.showSnackBar(_scaffoldKey, AuthService.friendlyError(e));
    } catch (_) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthHeaderLabel(headerLabel: 'Log In'),
                    const SizedBox(height: 50),

                    // Email
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

                    // Password
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        obscureText: !_passwordVisible,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password.';
                          }
                          return null;
                        },
                        onChanged: (v) => _password = v,
                        decoration: textFormDecoration.copyWith(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            icon: Icon(
                              _passwordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),

                    HaveAccount(
                      haveAccount: "Don't have an account? ",
                      actionLabel: 'Sign Up',
                      onPressed: () => Navigator.pushReplacementNamed(context, '/customer_signup'),
                    ),

                    const SizedBox(height: 20),

                    // Log In button
                    _loading
                        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                        : AuthButton(mainButtonLabel: 'Log In', onPressed: _login),

                    const SizedBox(height: 24),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _googleLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                        : _GoogleSignInButton(onPressed: _googleLogin),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Image(image: AssetImage('images/inapp/google.jpg'), height: 35),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
