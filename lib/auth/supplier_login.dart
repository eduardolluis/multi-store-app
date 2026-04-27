import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/auth/forgot_password_screen.dart';
import 'package:multi_store_app/auth/verify_email_screen.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class SupplierLogin extends StatefulWidget {
  const SupplierLogin({super.key});

  @override
  State<SupplierLogin> createState() => _SupplierLoginState();
}

class _SupplierLoginState extends State<SupplierLogin> {
  String _email = '';
  String _password = '';

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  bool _passwordVisible = false;
  bool _loading = false;
  bool _googleLoading = false;

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
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen(nextRoute: '/supplier_home')),
        );
        return;
      }

      _formKey.currentState!.reset();
      Navigator.pushReplacementNamed(context, '/supplier_home');
    } on FirebaseAuthException catch (e) {
      MyMessageHandler.showSnackBar(_scaffoldKey, AuthService.friendlyError(e));
    } catch (_) {
      MyMessageHandler.showSnackBar(_scaffoldKey, 'Login failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _googleLoading = true);

    try {
      final cred = await AuthService.instance.signInWithGoogle();

      if (cred == null) return;
      if (!mounted) return;

      final uid = cred.user!.uid;

      final docExists = await AuthService.instance.userDocumentExists(
        uid: uid,
        collection: 'suppliers',
      );

      if (!docExists) {
        final googleUser = cred.user!;

        await AuthService.instance.createSupplierDocument(
          uid: uid,
          name: googleUser.displayName ?? 'Google Supplier',
          email: googleUser.email ?? '',
          profileImage: googleUser.photoURL ?? '',
          storeName: '',
          storeDescription: '',
          storeAddress: '',
          storeEmail: googleUser.email ?? '',
          storePhone: '',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/supplier_home');
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
                    AuthHeaderLabel(headerLabel: 'Supplier Log In'),

                    const SizedBox(height: 50),

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
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                            icon: Icon(
                              _passwordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
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
                      haveAccount: "Don't have a supplier account? ",
                      actionLabel: 'Register',
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/supplier_signup');
                      },
                    ),

                    const SizedBox(height: 20),

                    _loading
                        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                        : AuthButton(mainButtonLabel: 'Log In', onPressed: _login),

                    const SizedBox(height: 20),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('or', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _googleLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                        : _GoogleButton(onPressed: _googleLogin),
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

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Image(image: AssetImage('images/inapp/google.jpg'), height: 28),
            SizedBox(width: 12),
            Text('Continue with Google', style: TextStyle(color: Colors.black87, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
 