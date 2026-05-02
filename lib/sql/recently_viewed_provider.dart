import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:multi_store_app/sql/database_helper.dart';

class RecentlyViewedProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final List<Map<String, dynamic>> _items = [];
  bool _loaded = false;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool get hasItems => _items.isNotEmpty;


  Future<void> loadFromDb() async {
    if (_loaded) return;

    final rows = await _db.getRecentlyViewed();
    _items.clear();

    for (final row in rows) {
      _items.add(_rowToMap(row));
    }

    _loaded = true;
    notifyListeners();
  }


  Future<void> addProduct({
    required String documentId,
    required String supplierId,
    required String name,
    required double price,
    required double salePrice,
    required int quantity,
    required List imagesUrl,
  }) async {
    await _db.saveRecentlyViewed({
      'document_id': documentId,
      'supplier_id': supplierId,
      'name': name,
      'price': price,
      'sale_price': salePrice,
      'quantity': quantity,
      'images_url': jsonEncode(imagesUrl),
    });

    _items.removeWhere((item) => item['document_id'] == documentId);
    _items.insert(0, {
      'document_id': documentId,
      'supplier_id': supplierId,
      'name': name,
      'price': price,
      'sale_price': salePrice,
      'quantity': quantity,
      'images_url': imagesUrl,
    });

    if (_items.length > 30) {
      _items.removeRange(30, _items.length);
    }

    notifyListeners();
  }


  Future<void> clearAll() async {
    _items.clear();
    await _db.clearRecentlyViewed();
    notifyListeners();
  }


  static Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    List imagesList;
    try {
      imagesList = jsonDecode(row['images_url'] as String) as List;
    } catch (_) {
      imagesList = [row['images_url']];
    }

    return {
      'document_id': row['document_id'],
      'supplier_id': row['supplier_id'],
      'name': row['name'],
      'price': (row['price'] as num).toDouble(),
      'sale_price': (row['sale_price'] as num).toDouble(),
      'quantity': row['quantity'],
      'images_url': imagesList,
    };
  }
}
