import 'package:flutter/foundation.dart';
import 'package:multi_store_app/sql/database_helper.dart';

class ProductNotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  final Map<String, String> _notes = {};


  Future<void> saveNote(String documentId, String note) async {
    if (note.trim().isEmpty) {
      await deleteNote(documentId);
      return;
    }

    await _db.saveProductNote(documentId, note.trim());
    _notes[documentId] = note.trim();
    notifyListeners();
  }

  Future<String?> getNote(String documentId) async {
    if (_notes.containsKey(documentId)) {
      return _notes[documentId];
    }

    final note = await _db.getProductNote(documentId);
    if (note != null) {
      _notes[documentId] = note;
    }
    return note;
  }

  String? getCachedNote(String documentId) => _notes[documentId];

  bool hasNote(String documentId) => _notes.containsKey(documentId) && _notes[documentId]!.isNotEmpty;


  Future<void> deleteNote(String documentId) async {
    _notes.remove(documentId);
    await _db.deleteProductNote(documentId);
    notifyListeners();
  }
}
