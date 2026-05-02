import 'package:flutter/foundation.dart';
import 'package:multi_store_app/sql/database_helper.dart';

class SearchHistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<String> _history = [];
  bool _loaded = false;

  List<String> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;


  Future<void> loadFromDb() async {
    if (_loaded) return;
    _history = await _db.getSearchHistory();
    _loaded = true;
    notifyListeners();
  }


  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    await _db.saveSearch(query.trim());

    _history.remove(query.trim());
    _history.insert(0, query.trim());

    if (_history.length > 20) {
      _history = _history.sublist(0, 20);
    }

    notifyListeners();
  }


  Future<void> deleteSearch(String query) async {
    _history.remove(query);
    await _db.deleteSearch(query);
    notifyListeners();
  }


  Future<void> clearAll() async {
    _history.clear();
    await _db.clearSearchHistory();
    notifyListeners();
  }

  List<String> getSuggestions(String prefix) {
    if (prefix.trim().isEmpty) return _history;
    final lower = prefix.toLowerCase();
    return _history.where((q) => q.toLowerCase().contains(lower)).toList();
  }
}
