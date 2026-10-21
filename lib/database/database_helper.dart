import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE,
        name TEXT,
        price REAL,
        cost REAL,
        quantity INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL,
        date TEXT
      )
    ''');
  }

  // 1. إرجاع كل المنتجات
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // 2. إرجاع كل المبيعات (التي طلبها سيرفر البناء)
  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await instance.database;
    return await db.query('sales');
  }

  // 3. إضافة أو تحديث منتج من السحابة
  Future<int> insertOrUpdateProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    String barcode = product['barcode'] ?? 'NO_BC_${DateTime.now().millisecondsSinceEpoch}';
    
    List<Map<String, dynamic>> existing = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'products',
        {
          'name': product['name'],
          'price': product['price'],
          'cost': product['cost'],
          'quantity': product['quantity'],
        },
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } else {
      return await db.insert('products', {
        'barcode': barcode,
        'name': product['name'],
        'price': product['price'],
        'cost': product['cost'],
        'quantity': product['quantity'],
      });
    }
  }

  // 4. إضافة مبيعات
  Future<int> insertSale(double total) async {
    final db = await instance.database;
    return await db.insert('sales', {
      'total_amount': total,
      'date': DateTime.now().toIso8601String(),
    });
  }
}
