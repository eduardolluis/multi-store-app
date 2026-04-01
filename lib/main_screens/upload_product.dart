// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  late double price;
  late int quantity;
  late String productName;
  late String productDescription;

  final ImagePicker _picker = ImagePicker();

  List<XFile>? imagesFilesList = [];

  dynamic _pickedImageError;

  void pickProductImages() async {
    try {
      final pickedImages = await _picker.pickMultiImage(
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );

      if (pickedImages != null) {
        setState(() {
          imagesFilesList = pickedImages;
        });
      }
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
      print(_pickedImageError);
    }
  }

  Widget previewImages() {
    if (imagesFilesList != null && imagesFilesList!.isNotEmpty) {
      return SizedBox(
        height: double.infinity,
        child: ListView.builder(
          itemCount: imagesFilesList!.length,
          itemBuilder: (context, index) {
            return Image.file(File(imagesFilesList![index].path));
          },
        ),
      );
    } else {
      return const Center(
        child: Text(
          "You have not \n \n picked any products yet!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }
  }

  void uploadProduct() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (imagesFilesList == null || imagesFilesList!.isEmpty) {
        MyMessageHandler.showSnackBar(_scaffoldKey, "Please pick image first");
        return;
      }

      print("You have picked ${imagesFilesList!.length} images");
      print("Price: $price");
      print("Quantity: $quantity");
      print("Product Name: $productName");
      print("Product Description: $productDescription");

      setState(() {
        imagesFilesList = [];
      });

      _formKey.currentState!.reset();
    } else {
      MyMessageHandler.showSnackBar(_scaffoldKey, "please fill all fields");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            color: Colors.blueGrey[200],
                            height: MediaQuery.of(context).size.width * 0.5,
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Center(
                              child:
                                  imagesFilesList == null ||
                                      imagesFilesList!.isEmpty
                                  ? const Text(
                                      "You have not \n \n picked any products yet!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16),
                                    )
                                  : previewImages(),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                imagesFilesList = [];
                              });
                            },
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                    child: Divider(color: Colors.yellow, thickness: 1.5),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.38,
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Price is required";
                          } else if (!value.isValidPrice()) {
                            return "Invalid price";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          price = double.parse(value!);
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: textFormDecor.copyWith(
                          labelText: "Price",
                          hintText: "Price .. \$",
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Quantity is required";
                          } else if (!value.isValidQuantity()) {
                            return "Please enter a valid quantity";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          quantity = int.parse(value!);
                        },
                        keyboardType: TextInputType.number,
                        decoration: textFormDecor.copyWith(
                          labelText: "Quantity",
                          hintText: "Add Quantity ..",
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      validator: (value) =>
                          value!.isEmpty ? "Enter Product Name" : null,
                      maxLength: 100,
                      maxLines: 3,
                      decoration: textFormDecor.copyWith(
                        labelText: "Product Name",
                      ),
                      onSaved: (value) {
                        productName = value!;
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      maxLength: 500,
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? "Enter description" : null,
                      decoration: textFormDecor.copyWith(
                        labelText: "Product Description",
                      ),
                      onSaved: (value) {
                        productDescription = value!;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FloatingActionButton(
                onPressed: pickProductImages,
                backgroundColor: Colors.yellow,
                child: const Icon(Icons.photo_library, color: Colors.black),
              ),
            ),
            FloatingActionButton(
              onPressed: uploadProduct,
              backgroundColor: Colors.yellow,
              child: const Icon(Icons.upload, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

var textFormDecor = InputDecoration(
  labelStyle: const TextStyle(color: Colors.purple),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.yellow, width: 1),
    borderRadius: BorderRadius.circular(10),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
    borderRadius: BorderRadius.circular(10),
  ),
);

extension QuantityValidator on String {
  bool isValidQuantity() {
    return RegExp(r'^[1-9][0-9]*$').hasMatch(this);
  }
}

extension PriceValidator on String {
  bool isValidPrice() {
    return RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]{1,2})?$').hasMatch(this);
  }
}
