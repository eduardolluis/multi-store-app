import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  late String productId;

  bool processing = false;

  String? mainCategoryValue;
  String? subCategoryValue;

  final ImagePicker _picker = ImagePicker();

  List<XFile> imagesFilesList = [];
  List<String> imagesUrlList = [];

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
        return [];
    }
  }

  void pickProductImages() async {
    final pickedImages = await _picker.pickMultiImage(
      maxHeight: 300,
      maxWidth: 300,
      imageQuality: 95,
    );

    setState(() {
      imagesFilesList = pickedImages;
    });
  }

  Widget previewImages() {
    if (imagesFilesList.isEmpty) {
      return const Center(child: Text("No images selected"));
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: imagesFilesList.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagesFilesList[index].path),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Future<void> uploadImages() async {
    final supabase = Supabase.instance.client;

    imagesUrlList.clear();

    final uploadFutures = imagesFilesList.map((image) async {
      final file = File(image.path);

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${image.name}";

      final path = 'products/$fileName';

      await supabase.storage.from('products').upload(path, file);

      return supabase.storage.from('products').getPublicUrl(path);
    }).toList();

    imagesUrlList = await Future.wait(uploadFutures);
  }

  Future<void> uploadData() async {
    final firestore = FirebaseFirestore.instance;

    productId = const Uuid().v4();

    await firestore.collection('products').doc(productId).set({
      "productId": productId,
      'quantity': quantity,
      'category': mainCategoryValue,
      'subcategory': subCategoryValue,
      'price': price,
      'productName': productName,
      'productDescription': productDescription,
      'images': imagesUrlList,
      'discount': 0,
      'cid': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void uploadProduct() async {
    if (processing) return;

    if (!_formKey.currentState!.validate()) {
      MyMessageHandler.showSnackBar(_scaffoldKey, "Fill all fields");
      return;
    }

    if (imagesFilesList.isEmpty) {
      MyMessageHandler.showSnackBar(_scaffoldKey, "Pick images first");
      return;
    }

    _formKey.currentState!.save();

    setState(() => processing = true);

    try {
      await uploadImages();
      await uploadData();

      MyMessageHandler.showSnackBar(_scaffoldKey, "Uploaded!");

      setState(() {
        imagesFilesList.clear();
        imagesUrlList.clear();
        mainCategoryValue = null;
        subCategoryValue = null;
      });

      _formKey.currentState!.reset();
    } catch (e) {
      print(e);
      MyMessageHandler.showSnackBar(_scaffoldKey, "Upload failed");
    } finally {
      setState(() => processing = false);
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  height: 180,
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
                      DropdownButtonFormField<String>(
                        value: mainCategoryValue,
                        decoration: textFormDecor.copyWith(
                          labelText: "Main Category",
                        ),
                        items: maincateg.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: processing
                            ? null
                            : (value) {
                                setState(() {
                                  mainCategoryValue = value;
                                  subCategoryValue = null;
                                });
                              },
                        validator: (value) =>
                            value == null ? "Select category" : null,
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
                        onChanged: processing
                            ? null
                            : (value) {
                                setState(() {
                                  subCategoryValue = value;
                                });
                              },
                        validator: (value) =>
                            value == null ? "Select subcategory" : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

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
                        decoration: textFormDecor.copyWith(labelText: "Price"),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        enabled: !processing,
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
                        enabled: !processing,
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
                        decoration: textFormDecor.copyWith(
                          labelText: "Product Name",
                        ),
                        enabled: !processing,
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
                        enabled: !processing,
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

        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: processing
                  ? null
                  : (imagesFilesList.isEmpty
                        ? pickProductImages
                        : () {
                            setState(() {
                              imagesFilesList.clear();
                            });
                          }),
              backgroundColor: Colors.yellow,
              icon: Icon(
                imagesFilesList.isEmpty ? Icons.photo : Icons.delete,
                color: Colors.black,
              ),
              label: Text(
                imagesFilesList.isEmpty ? "Gallery" : "Clear",
                style: const TextStyle(color: Colors.black),
              ),
            ),

            const SizedBox(width: 10),

            FloatingActionButton.extended(
              onPressed: processing ? null : uploadProduct,
              backgroundColor: Colors.yellow,
              icon: processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.upload, color: Colors.black),
              label: Text(
                processing ? "Uploading..." : "Upload",
                style: const TextStyle(color: Colors.black),
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
