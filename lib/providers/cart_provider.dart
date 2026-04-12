import 'package:flutter/foundation.dart';
import 'package:multi_store_app/providers/product_class.dart';

class Cart extends ChangeNotifier {
  final List<Product> _list = [];

  List<Product> get getItems => _list;

  double get totalPrice {
    var total = 0.0;
    for (var item in _list) {
      total += item.salePrice * item.qty;
    }
    return total;
  }

  int? get count => _list.length;

  void addItem(
    String name,
    double price,
    double salePrice,
    int qty,
    int quantity,
    List imagesUrl,
    String documentId,
    String supplierId,
  ) {
    final product = Product(
      name: name,
      price: price,
      salePrice: salePrice,
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
