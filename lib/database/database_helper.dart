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

  // 1. إضافة مادة جديدة (تستخدمها شاشة add_product_screen)
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    String barcode = (product['barcode'] != null && product['barcode'].toString().isNotEmpty)
        ? product['barcode']
        : 'NO_BC_${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic> row = Map.from(product);
    row['barcode'] = barcode;

    return await db.insert('products', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 2. إرجاع جميع المنتجات
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // 3. حذف مادة (تستخدمها شاشة product_list_screen)
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // 4. إتمام عملية بيع وحفظ الفاتورة (تستخدمها شاشة pos_screen)
  Future<int> completeSale(List<dynamic> cartItems, double totalAmount) async {
    final db = await instance.database;
    return await db.insert('sales', {
      'total_amount': totalAmount,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // 5. جلب كافة المبيعات والفواتير (تستخدمها شاشة sales_report_screen)
  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await instance.database;
    return await db.query('sales', orderBy: 'id DESC');
  }

  // 6. جلب المبيعات للسحابة
  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await instance.database;
    return await db.query('sales');
  }

  // 7. دمج وتحديث المادة من السحابة
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
}
