import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
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

  String mainCategoryValue = 'select category';
  String subCategoryValue = 'subCategory';

  final ImagePicker _picker = ImagePicker();
  List<XFile>? imagesFilesList = [];
  dynamic _pickedImageError;

  List<String> get currentSubCategories {
    switch (mainCategoryValue) {
      case 'men':
        return men;
      case 'women':
        return women;
      case 'electronics':
        return electronics;
      case 'accessories':
        return accessories;
      case 'shoes':
        return shoes;
      case 'home & garden':
        return homeandgarden;
      case 'beauty':
        return beauty;
      case 'kids':
        return kids;
      case 'bags':
        return bags;
      default:
        return ['subCategory'];
    }
  }

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

      if (mainCategoryValue == 'select category') {
        MyMessageHandler.showSnackBar(_scaffoldKey, "Please select a category");
        return;
      }

      if (subCategoryValue == 'subCategory') {
        MyMessageHandler.showSnackBar(
          _scaffoldKey,
          "Please select a subcategory",
        );
        return;
      }

      setState(() {
        imagesFilesList = [];
        mainCategoryValue = 'select category';
        subCategoryValue = 'subCategory';
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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Upload Product"),
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// 🔥 IMAGE PREVIEW CARD
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: previewImages(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 CATEGORY CARD
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black12),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Category",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          value: mainCategoryValue,
                          decoration: textFormDecor.copyWith(
                            labelText: "Main Category",
                          ),
                          items: maincateg.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              mainCategoryValue = value!;
                              subCategoryValue = currentSubCategories.first;
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          value: subCategoryValue,
                          decoration: textFormDecor.copyWith(
                            labelText: "Sub Category",
                          ),
                          items: currentSubCategories.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              subCategoryValue = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 FORM CARD
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: textFormDecor.copyWith(
                            labelText: "Price",
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return "Price required";
                            if (!value.isValidPrice()) return "Invalid price";
                            return null;
                          },
                          onSaved: (value) {
                            price = double.parse(value!);
                          },
                        ),

                        const SizedBox(height: 10),

                        TextFormField(
                          decoration: textFormDecor.copyWith(
                            labelText: "Quantity",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return "Quantity required";
                            if (!value.isValidQuantity()) {
                              return "Invalid quantity";
                            }
                            return null;
                          },
                          onSaved: (value) {
                            quantity = int.parse(value!);
                          },
                        ),

                        const SizedBox(height: 10),

                        TextFormField(
                          maxLines: 2,
                          decoration: textFormDecor.copyWith(
                            labelText: "Product Name",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Enter name" : null,
                          onSaved: (value) {
                            productName = value!;
                          },
                        ),

                        const SizedBox(height: 10),

                        TextFormField(
                          maxLines: 3,
                          decoration: textFormDecor.copyWith(
                            labelText: "Description",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Enter description" : null,
                          onSaved: (value) {
                            productDescription = value!;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),

        /// 🔥 BOTONES MÁS LIMPIOS
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: imagesFilesList!.isEmpty
                  ? pickProductImages
                  : () {
                      setState(() {
                        imagesFilesList = [];
                      });
                    },
              backgroundColor: Colors.yellow,
              icon: Icon(
                imagesFilesList!.isEmpty ? Icons.photo_library : Icons.delete,
                color: Colors.black,
              ),
              label: Text(
                imagesFilesList!.isEmpty ? "Gallery" : "Clear",
                style: const TextStyle(color: Colors.black),
              ),
            ),

            const SizedBox(width: 10),

            FloatingActionButton.extended(
              onPressed: uploadProduct,
              backgroundColor: Colors.yellow,
              icon: const Icon(Icons.upload, color: Colors.black),
              label: const Text(
                "Upload",
                style: TextStyle(color: Colors.black),
              ),
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
