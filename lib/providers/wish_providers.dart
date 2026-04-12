import 'package:flutter/foundation.dart';
import 'package:multi_store_app/providers/product_class.dart';

class Wish extends ChangeNotifier {
  final List<Product> _list = [];

  List<Product> get getWishItems => _list;

  int? get count => _list.length;

  Future<void> addWishItem(
    String name,
    double price,
    double salePrice,
    int qty,
    int quantity,
    List imagesUrl,
    String documentId,
    String supplierId,
  ) async {
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

  void removeItem(Product product) {
    _list.remove(product);
    notifyListeners();
  }

  void clearWishList() {
    _list.clear();
    notifyListeners();
  }

  void removeThis(String id) {
    _list.removeWhere((element) => element.documentId == id);
    notifyListeners();
  }
}
