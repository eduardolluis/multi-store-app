import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';

class CustomerSignup extends StatefulWidget {
  const CustomerSignup({super.key});

  @override
  State<CustomerSignup> createState() => _CustomerSignupState();
}

class _CustomerSignupState extends State<CustomerSignup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisibility = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  children: [
                    AuthHeaderLabel(headerLabel: 'Sign Up'),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 40,
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.purpleAccent,
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (kDebugMode) {
                                    print('pick image from camera');
                                  }
                                },
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  if (kDebugMode) {
                                    print('pick image from gallery');
                                  }
                                },
                                icon: Icon(Icons.photo, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please Enter Your Full Name";
                          } else {
                            return null;
                          }
                        },
                        decoration: textFormDecoration.copyWith(
                          labelText: "Full Name",
                          hintText: "Enter Your Full Name",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please Enter Your Email Address";
                          } else if (value.isValidEmail() == false) {
                            return "Please Enter A Valid Email Address";
                          } else if (value.isValidEmail() == true) {
                            return null;
                          }
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
                          if (value!.isEmpty) {
                            return "Please Enter Your Password";
                          } else {
                            return null;
                          }
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
                    HaveAccount(
                      haveAccount: "Already Have An Account?",
                      actionLabel: "Log In",
                      onPressed: () {},
                    ),
                    AuthButton(
                      mainButtonLabel: 'Sign Up',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (kDebugMode) {
                            print("valid");
                          }
                        } else {
                          if (kDebugMode) {
                            print("invalid");
                          }
                        }
                      },
                    ),
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

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
      r'^([a-zA-Z0-9]+)([\-\_\.])([a-zA-Z0-9]*)([@])([a-zA-Z0-9]{2,})([\.])([a-zA-Z0-9]{2,3})$',
    ).hasMatch(this);
  }
}
