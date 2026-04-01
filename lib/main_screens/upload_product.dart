import 'package:flutter/material.dart';
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
                      Container(
                        color: Colors.blueGrey[200],
                        height: MediaQuery.of(context).size.width * 0.5,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Center(
                          child: Text(
                            "You have not \n \n picked any products yet!",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
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
                          } else if (value.isValidPrice() != true) {
                            return "Invalid price ";
                          }
                          return null;
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: textFormDecor.copyWith(
                          labelText: "Price ",
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
                          } else if (value.isValidQuantity() != true) {
                            return "Please enter a valid quantity";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: textFormDecor.copyWith(
                          labelText: "Quantity ",
                          hintText: "Add Quantity ..",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        validator: (value) =>
                            value!.isEmpty ? "Please enter Product Name" : null,
                        maxLength: 100,
                        maxLines: 3,
                        decoration: textFormDecor.copyWith(
                          labelText: "Product Name",
                          hintText: "Enter Product Name ..",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) => value!.isEmpty
                            ? "Please enter Product description"
                            : null,
                        decoration: textFormDecor.copyWith(
                          labelText: "Product description",
                          hintText: "Enter Product description ..",
                        ),
                      ),
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
                onPressed: () {},
                backgroundColor: Colors.yellow,
                child: const Icon(Icons.photo_library, color: Colors.black),
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  print('all good');
                } else {
                  MyMessageHandler.showSnackBar(
                    _scaffoldKey,
                    "please fill all keys",
                  );
                }
              },
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
  labelText: "Price",
  hintText: "Price .. \$",
  labelStyle: TextStyle(color: Colors.purple),
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
