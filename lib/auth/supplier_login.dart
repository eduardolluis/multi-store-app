import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class SupplierLogin extends StatefulWidget {
  const SupplierLogin({super.key});

  @override
  State<SupplierLogin> createState() => _SupplierLoginState();
}

class _SupplierLoginState extends State<SupplierLogin> {
  String email = '';
  String password = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool passwordVisibility = true;
  bool processing = false;

  void logIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        processing = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        _formKey.currentState!.reset();

        Navigator.pushReplacementNamed(context, '/supplier_home');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          MyMessageHandler.showSnackBar(
            _scaffoldKey,
            "No User Found For That Email",
          );
        } else if (e.code == 'wrong-password') {
          MyMessageHandler.showSnackBar(
            _scaffoldKey,
            "Wrong Password Provided By User",
          );
        } else {
          MyMessageHandler.showSnackBar(
            _scaffoldKey,
            e.message ?? "Login Failed",
          );
        }
      } finally {
        setState(() {
          processing = false;
        });
      }
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthHeaderLabel(headerLabel: 'Log In'),
                      const SizedBox(height: 50),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please Enter Your Email Address";
                            } else if (!value.isValidEmail()) {
                              return "Please Enter A Valid Email Address";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            email = value;
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: textFormDecoration.copyWith(
                            labelText: "Email Address",
                            hintText: "Enter Your Email Address",
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextFormField(
                          obscureText: passwordVisibility,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please Enter Your Password";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            password = value;
                          },
                          decoration: textFormDecoration.copyWith(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  passwordVisibility = !passwordVisibility;
                                });
                              },
                              icon: Icon(
                                passwordVisibility
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.purple,
                              ),
                            ),
                            labelText: "Password",
                            hintText: "Enter Your Password",
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot Password ?",
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      HaveAccount(
                        haveAccount: "Don't Have An Account? ",
                        actionLabel: "Sign Up",
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/customer_signup',
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      processing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.purple,
                              ),
                            )
                          : AuthButton(
                              mainButtonLabel: 'Log In',
                              onPressed: logIn,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
