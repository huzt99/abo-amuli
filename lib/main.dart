import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const ProStoreApp());
}

class ProStoreApp extends StatelessWidget {
  const ProStoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الكاشير المحترف',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        fontFamily: 'Cairo',
      ),
      home: const DashboardScreen(),
    );
  }
}

// نموذج المادة والبيانات الشاملة
class ProductItem {
  final String barcode;
  String name;
  double unitPrice;
  double cartonPrice;
  int itemsPerCarton;
  int singleStock;
  int cartonStock;
  String category;

  ProductItem({
    required this.barcode,
    required this.name,
    required this.unitPrice,
    required this.cartonPrice,
    required this.itemsPerCarton,
    required this.singleStock,
    required this.cartonStock,
    required this.category,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  // قاعدة بيانات تجريبية تحاكي النظام الموضح في الفيديو
  final Map<String, ProductItem> _storeDatabase = {
    '123456789': ProductItem(
      barcode: '123456789',
      name: 'بيبسي 300 مل',
      unitPrice: 500,
      cartonPrice: 11000,
      itemsPerCarton: 24,
      singleStock: 15,
      cartonStock: 3,
      category: 'المشروبات',
    ),
  };

  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _salesHistory = [];

  // حقول إضافة مادة جديدة
  final TextEditingController _bcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uPriceController = TextEditingController();
  final TextEditingController _cPriceController = TextEditingController();
  final TextEditingController _ipcController = TextEditingController(text: '24');
  final TextEditingController _singleStockController = TextEditingController(text: '0');
  final TextEditingController _cartonStockController = TextEditingController(text: '0');

  void _addToCart(ProductItem product, String type) {
    setState(() {
      double price = type == 'single' ? product.unitPrice : product.cartonPrice;
      _cartItems.add({
        'name': product.name,
        'type': type == 'single' ? 'مفرد' : 'كارتون',
        'price': price,
        'barcode': product.barcode,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة ${product.name} إلى السلة'), duration: const Duration(milliseconds: 500)),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += item['price'];
    }
    return total;
  }

  Future<void> _completeSaleAndPrint() async {
    if (_cartItems.isEmpty) return;

    double total = _calculateTotal();
    
    // تسجيل المبيعات
    setState(() {
      _salesHistory.insert(0, {
        'items': List.from(_cartItems),
        'total': total,
        'time': DateTime.now().toString().substring(11, 19),
      });
      _cartItems.clear();
    });

    // طباعة الوصل الحراري
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('وصل مبيعات المحل', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ..._salesHistory.first['items'].map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item['name']} (${item['type']})'),
                  pw.Text('${item['price']} د.ع'),
                ],
              )).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي الكلي:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('$total د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('شكراً لتعاملكم معنا!'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت العملية وطباعة الوصل بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 1. شاشة نقطة البيع الرئيسية (POS) المماثلة للفيديو
      Row(
        children: [
          // القسم الأيمن: سلة البيع والحسابات
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blueGrey[900],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('قائمة البيع الحالية', style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _completeSaleAndPrint,
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('إتمام البيع والطباعة'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('النوع: ${item['type']}'),
                        trailing: Text('${item['price']} د.ع', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        leading: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _cartItems.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_calculateTotal()} د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // القسم الأيسر: الأزرار السريعة والمجموعات
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey[900],
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('الأزرار السريعة والمواد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _storeDatabase.length,
                      itemBuilder: (context, index) {
                        String key = _storeDatabase.keys.elementAt(index);
                        ProductItem prod = _storeDatabase[key]!;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                          onPressed: () => _addToCart(prod, 'single'),
                          child: Text(prod.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // 2. ماسح الباركود بالكاميرا
      Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('وجه كاميرا الموبايل نحو الباركود', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 350,
              width: 350,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        String code = barcode.rawValue!;
                        if (_storeDatabase.containsKey(code)) {
                          _addToCart(_storeDatabase[code]!, 'single');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('الباركود غير مسجل: $code')),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. شاشة إضافة مادة جديدة (محاكاة لشاشة الإضافة في الكمبيوتر)
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة مادة جديدة للمخزن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 12),
                TextField(controller: _bcController, decoration: const InputDecoration(labelText: 'رقم الباركود')),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المادة')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _uPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المفرد'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _cPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكارتون'))),
                  ],
                ),
                TextField(controller: _ipcController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد القطع في الكارتون')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _singleStockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القطع الحالية'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _cartonStockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكارتونات الحالية'))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      String code = _bcController.text.trim();
                      if (code.isNotEmpty) {
                        setState(() {
                          _storeDatabase[code] = ProductItem(
                            barcode: code,
                            name: _nameController.text,
                            unitPrice: double.tryParse(_uPriceController.text) ?? 0,
                            cartonPrice: double.tryParse(_cPriceController.text) ?? 0,
                            itemsPerCarton: int.tryParse(_ipcController.text) ?? 24,
                            singleStock: int.tryParse(_singleStockController.text) ?? 0,
                            cartonStock: int.tryParse(_cartonStockController.text) ?? 0,
                            category: 'عام',
                          );
                        });
                        _bcController.clear();
                        _nameController.clear();
                        _uPriceController.clear();
                        _cPriceController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المادة بنجاح')));
                      }
                    },
                    child: const Text('حفظ المادة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الكاشير والمخازن الذكي (موبايل)'),
        centerTitle: true,
      ),
      body: pages[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'نقطة البيع'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'الماسح الكاميرا'),
          NavigationDestination(icon: Icon(Icons.add_box), label: 'إضافة مادة'),
        ],
      ),
    );
  }
}
