import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
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
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        cost REAL,
        expiry TEXT,
        show_in_touch INTEGER NOT NULL
      )
    ''');

    // جدول الفواتير (المبيعات)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // إدخال منتج جديد
  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('products', row);
  }

  // حذف منتج
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // جلب المنتجات التي تظهر في أزرار اللمس الرئيسية
  Future<List<Map<String, dynamic>>> getTouchProducts() async {
    final db = await database;
    return await db.query('products', where: 'show_in_touch = ?', whereArgs: [1]);
  }

  // جلب كل المنتجات للمخزن
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products');
  }

  // تسجيل فاتورة جديدة وتحديث المخزون
  Future<void> completeSale(List<Map<String, dynamic>> cartItems, double totalAmount) async {
    final db = await database;
    await db.transaction((txn) async {
      // إدخال الفاتورة
      await txn.insert('invoices', {
        'total_amount': totalAmount,
        'timestamp': DateTime.now().toString(),
      });

      // خصم الكميات من المخزون
      for (var item in cartItems) {
        int id = item['id'];
        double soldQty = item['cart_qty'];
        
        // جلب الكمية الحالية
        var productList = await txn.query('products', where: 'id = ?', whereArgs: [id]);
        if (productList.isNotEmpty) {
          double currentQty = productList.first['quantity'] as double;
          double newQty = currentQty - soldQty;
          
          await txn.update(
            'products',
            {'quantity': newQty < 0 ? 0 : newQty},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  // جلب الفواتير لكشف المبيعات
  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'id DESC');
  }
}
