import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const int _version = 1;
  static const String _dbName = 'multi_store.db';

  static const String tableCart = 'cart';
  static const String tableWishlist = 'wishlist';
  static const String tableSearchHistory = 'search_history';
  static const String tableRecentlyViewed = 'recently_viewed';
  static const String tableProductNotes = 'product_notes';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCart (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id  TEXT    NOT NULL UNIQUE,
        supplier_id  TEXT    NOT NULL,
        name         TEXT    NOT NULL,
        price        REAL    NOT NULL,
        sale_price   REAL    NOT NULL,
        qty          INTEGER NOT NULL DEFAULT 1,
        quantity     INTEGER NOT NULL DEFAULT 1,
        images_url   TEXT    NOT NULL,
        added_at     TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableWishlist (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id  TEXT    NOT NULL UNIQUE,
        supplier_id  TEXT    NOT NULL,
        name         TEXT    NOT NULL,
        price        REAL    NOT NULL,
        sale_price   REAL    NOT NULL,
        qty          INTEGER NOT NULL DEFAULT 1,
        quantity     INTEGER NOT NULL DEFAULT 1,
        images_url   TEXT    NOT NULL,
        added_at     TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSearchHistory (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        query      TEXT    NOT NULL UNIQUE,
        searched_at TEXT   NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRecentlyViewed (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id  TEXT    NOT NULL UNIQUE,
        supplier_id  TEXT    NOT NULL,
        name         TEXT    NOT NULL,
        price        REAL    NOT NULL,
        sale_price   REAL    NOT NULL,
        quantity     INTEGER NOT NULL DEFAULT 1,
        images_url   TEXT    NOT NULL,
        viewed_at    TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProductNotes (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT    NOT NULL UNIQUE,
        note        TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cart_document_id ON $tableCart(document_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_wish_document_id ON $tableWishlist(document_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_search_query ON $tableSearchHistory(query)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recent_viewed_at ON $tableRecentlyViewed(viewed_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Espacio para futuras migraciones.
  }


  Future<int> insertCartItem(Map<String, dynamic> item) async {
    final db = await database;
    return db.insert(
      tableCart,
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllCartItems() async {
    final db = await database;
    return db.query(tableCart, orderBy: 'added_at ASC');
  }

  Future<Map<String, dynamic>?> getCartItemById(String documentId) async {
    final db = await database;
    final result = await db.query(
      tableCart,
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCartQty(String documentId, int qty) async {
    final db = await database;
    return db.update(
      tableCart,
      {'qty': qty},
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<int> deleteCartItem(String documentId) async {
    final db = await database;
    return db.delete(
      tableCart,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<int> clearCart() async {
    final db = await database;
    return db.delete(tableCart);
  }

  Future<double> getCartTotal() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(sale_price * qty) AS total FROM $tableCart',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getCartCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $tableCart');
    return (result.first['count'] as int?) ?? 0;
  }


  Future<int> insertWishItem(Map<String, dynamic> item) async {
    final db = await database;
    return db.insert(
      tableWishlist,
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllWishItems() async {
    final db = await database;
    return db.query(tableWishlist, orderBy: 'added_at DESC');
  }

  Future<bool> isInWishlist(String documentId) async {
    final db = await database;
    final result = await db.query(
      tableWishlist,
      columns: ['id'],
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> deleteWishItem(String documentId) async {
    final db = await database;
    return db.delete(
      tableWishlist,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<int> clearWishlist() async {
    final db = await database;
    return db.delete(tableWishlist);
  }

  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final db = await database;
    await db.rawInsert(
      '''
      INSERT INTO $tableSearchHistory (query, searched_at)
      VALUES (?, datetime('now'))
      ON CONFLICT(query) DO UPDATE SET searched_at = datetime('now')
      ''',
      [query.trim()],
    );
    await db.rawDelete(
      '''
      DELETE FROM $tableSearchHistory
      WHERE id NOT IN (
        SELECT id FROM $tableSearchHistory
        ORDER BY searched_at DESC
        LIMIT 20
      )
      ''',
    );
  }

  Future<List<String>> getSearchHistory() async {
    final db = await database;
    final result = await db.query(
      tableSearchHistory,
      columns: ['query'],
      orderBy: 'searched_at DESC',
      limit: 20,
    );
    return result.map((r) => r['query'] as String).toList();
  }

  Future<int> deleteSearch(String query) async {
    final db = await database;
    return db.delete(
      tableSearchHistory,
      where: 'query = ?',
      whereArgs: [query],
    );
  }

  Future<int> clearSearchHistory() async {
    final db = await database;
    return db.delete(tableSearchHistory);
  }


  Future<void> saveRecentlyViewed(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert(
      tableRecentlyViewed,
      {...product, 'viewed_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.rawDelete(
      '''
      DELETE FROM $tableRecentlyViewed
      WHERE id NOT IN (
        SELECT id FROM $tableRecentlyViewed
        ORDER BY viewed_at DESC
        LIMIT 30
      )
      ''',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    final db = await database;
    return db.query(
      tableRecentlyViewed,
      orderBy: 'viewed_at DESC',
      limit: 30,
    );
  }

  Future<int> clearRecentlyViewed() async {
    final db = await database;
    return db.delete(tableRecentlyViewed);
  }


  Future<void> saveProductNote(String documentId, String note) async {
    final db = await database;
    await db.insert(
      tableProductNotes,
      {
        'document_id': documentId,
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getProductNote(String documentId) async {
    final db = await database;
    final result = await db.query(
      tableProductNotes,
      columns: ['note'],
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['note'] as String : null;
  }

  Future<int> deleteProductNote(String documentId) async {
    final db = await database;
    return db.delete(
      tableProductNotes,
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableCart);
    await db.delete(tableWishlist);
    await db.delete(tableSearchHistory);
    await db.delete(tableRecentlyViewed);
    await db.delete(tableProductNotes);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
