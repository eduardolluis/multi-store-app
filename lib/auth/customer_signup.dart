import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class CustomerSignup extends StatefulWidget {
  const CustomerSignup({super.key});

  @override
  State<CustomerSignup> createState() => _CustomerSignupState();
}

class _CustomerSignupState extends State<CustomerSignup> {
  late String name;
  late String email;
  late String password;
  late String profileImage;
  late String _uid;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool passwordVisibility = false;
  bool procesing = false;

  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  dynamic _pickedImageError;

  CollectionReference customers = FirebaseFirestore.instance.collection(
    'customers',
  );

  void _pickImageFromCamera() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );
      setState(() {
        _imageFile = pickedImage;
      });
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
      print(_pickedImageError);
    }
  }

  void _pickImageFromGallery() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );
      setState(() {
        _imageFile = pickedImage;
      });
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
      print(_pickedImageError);
    }
  }

  void signUp() async {
    if (!_formKey.currentState!.validate()) {
      MyMessageHandler.showSnackBar(_scaffoldKey, "Fill all fields");
      return;
    }

    if (_imageFile == null) {
      MyMessageHandler.showSnackBar(_scaffoldKey, "Pick an image");
      return;
    }

    setState(() {
      procesing = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _uid = FirebaseAuth.instance.currentUser!.uid;

      final supabase = Supabase.instance.client;

      final fileName = '${_uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('images')
          .upload(fileName, File(_imageFile!.path));

      profileImage = supabase.storage.from('images').getPublicUrl(fileName);

      await customers.doc(_uid).set({
        'name': name,
        'email': email,
        'profileImage': profileImage,
        'phone': "",
        'address': "",
        'cid': _uid,
      });

      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null;
        procesing = false;
      });

      Navigator.pushReplacementNamed(context, '/customer_home');
    } on FirebaseAuthException catch (e) {
      setState(() => procesing = false);

      if (e.code == 'weak-password') {
        MyMessageHandler.showSnackBar(_scaffoldKey, "Weak password");
      } else if (e.code == 'email-already-in-use') {
        MyMessageHandler.showSnackBar(_scaffoldKey, "Email already in use");
      } else {
        MyMessageHandler.showSnackBar(_scaffoldKey, "Auth error");
      }
    } catch (e) {
      setState(() => procesing = false);
      MyMessageHandler.showSnackBar(_scaffoldKey, "Error: $e");
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
                              backgroundImage: _imageFile == null
                                  ? null
                                  : FileImage(File(_imageFile!.path)),
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
                                    _pickImageFromCamera();
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
                                    _pickImageFromGallery();
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
                          onChanged: (value) {
                            name = value;
                          },
                          // controller: _nameController,
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
                            if (value!.isEmpty) {
                              return "Please Enter Your Password";
                            } else {
                              return null;
                            }
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
                      HaveAccount(
                        haveAccount: "Already Have An Account?",
                        actionLabel: "Log In",
                        onPressed: () {},
                      ),
                      AuthButton(
                        mainButtonLabel: 'Sign Up',
                        onPressed: () {
                          signUp();
                        },
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
