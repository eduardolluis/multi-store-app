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
  void increase() {
    qty++;
  }

  void decrease() {
    qty--;
  }
}

class Cart extends ChangeNotifier {
  final List<Product> _list = [];
  List<Product> get getItems {
    return _list;
  }

  double get totalPrice {
    var total = 0.0;

    for (var item in _list) {
      total += item.price * item.qty;
    }
    return total;
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

  void increment(Product product) {
    product.increase();
    notifyListeners();
  }

  void reduceByOne(Product product) {
    product.decrease();
    notifyListeners();
  }

  void removeItem(Product product) {
    _list.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _list.clear();
    notifyListeners();
  }
}
