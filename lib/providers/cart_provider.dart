import 'package:flutter/material.dart';

class Product {
  String name;
  double price;
  int qty;
  int quantity;
  List imagesUrl;
  String documentId;
  String supplierId;
  Product({
    required this.name,
    required this.price,
    required this.qty,
    required this.quantity,
    required this.imagesUrl,
    required this.documentId,
    required this.supplierId,
  });
}

class Cart extends ChangeNotifier {
  final List<Product> _list = [];
  List<Product> get getItems {
    return _list;
  }

  int? get count {
    return _list.length;
  }

  void addItem(
    String name,
    double price,
    int qty,
    int quantity,
    List imagesUrl,
    String documentId,
    String supplierId,
  ) {
    final product = Product(
      name: name,
      price: price,
      qty: qty,
      quantity: quantity,
      imagesUrl: imagesUrl,
      documentId: documentId,
      supplierId: supplierId,
    );
    _list.add(product);
    notifyListeners();
  }
}
