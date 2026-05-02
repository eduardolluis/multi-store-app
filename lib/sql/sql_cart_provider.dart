import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:multi_store_app/providers/product_class.dart';
import 'package:multi_store_app/sql/database_helper.dart';

class SqlCartProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final List<Product> _items = [];
  bool _loaded = false;

  List<Product> get getItems => _items;
  bool get isLoaded => _loaded;
  int get count => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.salePrice * item.qty);
  }

  Future<void> loadFromDb() async {
    if (_loaded) return;

    final rows = await _db.getAllCartItems();
    _items.clear();

    for (final row in rows) {
      _items.add(_rowToProduct(row));
    }

    _loaded = true;
    notifyListeners();
  }


  Future<void> addItem({
    required String name,
    required double price,
    required double salePrice,
    required int qty,
    required int quantity,
    required List imagesUrl,
    required String documentId,
    required String supplierId,
  }) async {
    final existing = _findById(documentId);

    if (existing != null) {
      existing.increase();
      await _db.updateCartQty(documentId, existing.qty);
    } else {
      await _db.insertCartItem({
        'document_id': documentId,
        'supplier_id': supplierId,
        'name': name,
        'price': price,
        'sale_price': salePrice,
        'qty': qty,
        'quantity': quantity,
        'images_url': jsonEncode(imagesUrl),
        'added_at': DateTime.now().toIso8601String(),
      });

      _items.add(Product(
        name: name,
        price: price,
        salePrice: salePrice,
        qty: qty,
        quantity: quantity,
        imagesUrl: imagesUrl,
        documentId: documentId,
        supplierId: supplierId,
      ));
    }

    notifyListeners();
  }


  Future<void> increment(Product product) async {
    product.increase();
    await _db.updateCartQty(product.documentId, product.qty);
    notifyListeners();
  }


  Future<void> reduceByOne(Product product) async {
    product.decrease();
    await _db.updateCartQty(product.documentId, product.qty);
    notifyListeners();
  }


  Future<void> removeItem(Product product) async {
    _items.remove(product);
    await _db.deleteCartItem(product.documentId);
    notifyListeners();
  }


  bool isInCart(String documentId) {
    return _items.any((p) => p.documentId == documentId);
  }


  Future<void> clearCart() async {
    _items.clear();
    await _db.clearCart();
    notifyListeners();
  }


  Future<double> getTotalFromDb() async {
    return _db.getCartTotal();
  }


  Product? _findById(String documentId) {
    try {
      return _items.firstWhere((p) => p.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  static Product _rowToProduct(Map<String, dynamic> row) {
    final rawImages = row['images_url'] as String;
    final List imagesList = _parseImages(rawImages);

    return Product(
      name: row['name'] as String,
      price: (row['price'] as num).toDouble(),
      salePrice: (row['sale_price'] as num).toDouble(),
      qty: row['qty'] as int,
      quantity: row['quantity'] as int,
      imagesUrl: imagesList,
      documentId: row['document_id'] as String,
      supplierId: row['supplier_id'] as String,
    );
  }

  static List _parseImages(String raw) {
    try {
      return jsonDecode(raw) as List;
    } catch (_) {
      return [raw];
    }
  }
}
