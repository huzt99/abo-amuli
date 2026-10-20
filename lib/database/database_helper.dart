import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        expiry_date TEXT,
        alert_days INTEGER,
        is_quick INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        items_json TEXT NOT NULL,
        cashier_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.insert('users', {'username': 'admin', 'password': '123', 'role': 'admin'});
    await db.insert('users', {'username': 'cashier', 'password': '111', 'role': 'cashier'});
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  // الدوال المطلوبة بواسطة شاشة الـ POS
  Future<List<Map<String, dynamic>>> getTouchProducts() async {
    final db = await instance.database;
    return await db.query('products', where: 'is_quick = 1');
  }

  Future<void> completeSale(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    final db = await instance.database;
    
    // حفظ الفاتورة
    await db.insert('invoices', {
      'date': DateTime.now().toString(),
      'total_amount': totalAmount,
      'items_json': jsonEncode(cartItems),
      'cashier_name': 'مدير/كاشير'
    });

    // خصم الكميات من المخزن
    for (var item in cartItems) {
      int id = item['id'];
      double soldQty = item['sold_qty'] ?? 1.0;
      
      // جلب الكمية الحالية
      var result = await db.query('products', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        double currentQty = result.first['quantity'] as double;
        double newQty = currentQty - soldQty;
        if (newQty < 0) newQty = 0;

        await db.update(
          'products',
          {'quantity': newQty},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }
}
