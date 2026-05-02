import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:multi_store_app/providers/product_class.dart';
import 'package:multi_store_app/sql/database_helper.dart';

class SqlWishProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final List<Product> _items = [];
  bool _loaded = false;

  List<Product> get getWishItems => _items;
  bool get isLoaded => _loaded;
  int get count => _items.length;


  Future<void> loadFromDb() async {
    if (_loaded) return;

    final rows = await _db.getAllWishItems();
    _items.clear();

    for (final row in rows) {
      _items.add(_rowToProduct(row));
    }

    _loaded = true;
    notifyListeners();
  }


  Future<void> addWishItem({
    required String name,
    required double price,
    required double salePrice,
    required int qty,
    required int quantity,
    required List imagesUrl,
    required String documentId,
    required String supplierId,
  }) async {
    final alreadyIn = await _db.isInWishlist(documentId);
    if (alreadyIn) return;

    await _db.insertWishItem({
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

    _items.insert(
      0,
      Product(
        name: name,
        price: price,
        salePrice: salePrice,
        qty: qty,
        quantity: quantity,
        imagesUrl: imagesUrl,
        documentId: documentId,
        supplierId: supplierId,
      ),
    );

    notifyListeners();
  }


  bool isInWishlist(String documentId) {
    return _items.any((p) => p.documentId == documentId);
  }

  Future<bool> isInWishlistAsync(String documentId) async {
    return _db.isInWishlist(documentId);
  }


  Future<void> removeItem(Product product) async {
    _items.remove(product);
    await _db.deleteWishItem(product.documentId);
    notifyListeners();
  }

  Future<void> removeById(String documentId) async {
    _items.removeWhere((p) => p.documentId == documentId);
    await _db.deleteWishItem(documentId);
    notifyListeners();
  }

  Future<void> toggleWish({
    required String name,
    required double price,
    required double salePrice,
    required int qty,
    required int quantity,
    required List imagesUrl,
    required String documentId,
    required String supplierId,
  }) async {
    if (isInWishlist(documentId)) {
      await removeById(documentId);
    } else {
      await addWishItem(
        name: name,
        price: price,
        salePrice: salePrice,
        qty: qty,
        quantity: quantity,
        imagesUrl: imagesUrl,
        documentId: documentId,
        supplierId: supplierId,
      );
    }
  }


  Future<void> clearWishList() async {
    _items.clear();
    await _db.clearWishlist();
    notifyListeners();
  }


  static Product _rowToProduct(Map<String, dynamic> row) {
    final rawImages = row['images_url'] as String;
    List imagesList;
    try {
      imagesList = jsonDecode(rawImages) as List;
    } catch (_) {
      imagesList = [rawImages];
    }

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
}
