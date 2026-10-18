import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SmartStoreApp());
}

class SmartStoreApp extends StatelessWidget {
  const SmartStoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الكاشير والمخازن الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Cairo',
      ),
      home: const MainScreen(),
    );
  }
}

// نموذج بيانات المنتج
class Product {
  final String barcode;
  String name;
  int itemsPerCarton;
  double unitPrice;
  double cartonPrice;
  int singleStock;
  int cartonStock;

  Product({
    required this.barcode,
    required this.name,
    required this.itemsPerCarton,
    required this.unitPrice,
    required this.cartonPrice,
    required this.singleStock,
    required this.cartonStock,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // قاعدة البيانات المحلية للتطبيق
  final Map<String, Product> _database = {
    '6281001234567': Product(
      barcode: '6281001234567',
      name: 'مشروب غازي 300 مل',
      itemsPerCarton: 24,
      unitPrice: 500,
      cartonPrice: 11000,
      singleStock: 10,
      cartonStock: 2,
    ),
  };

  Product? _scannedProduct;
  String _lastScannedBarcode = '';
  final List<Map<String, dynamic>> _salesLog = [];

  // وحدات التحكم لحقول نموذج الإضافة
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _itemsPerCartonController = TextEditingController(text: '24');
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _cartonPriceController = TextEditingController();
  final TextEditingController _singleStockController = TextEditingController(text: '0');
  final TextEditingController _cartonStockController = TextEditingController(text: '0');

  // عند مسح باركود بالكاميرا
  void _onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (const barcode in barcodes) {
      if (barcode.rawValue != null) {
        String code = barcode.rawValue!;
        if (code != _lastScannedBarcode) {
          _lastScannedBarcode = code;
          setState(() {
            _scannedProduct = _database[code];
          });
          if (_scannedProduct == null) {
            // إذا لم تكن المادة موجودة، نقوم بنقل الباركود تلقائياً لحقل الإضافة
            _barcodeController.text = code;
          }
        }
        break;
      }
    }
  }

  // حفظ أو تحديث منتج في قاعدة البيانات
  void _saveProduct() {
    String barcode = _barcodeController.text.trim();
    String name = _nameController.text.trim();
    if (barcode.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الباركود واسم السلعة على الأقل!')),
      );
      return;
    }

    setState(() {
      _database[barcode] = Product(
        barcode: barcode,
        name: name,
        itemsPerCarton: int.tryParse(_itemsPerCartonController.text) ?? 24,
        unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
        cartonPrice: double.tryParse(_cartonPriceController.text) ?? 0.0,
        singleStock: int.tryParse(_singleStockController.text) ?? 0,
        cartonStock: int.tryParse(_cartonStockController.text) ?? 0,
      );
    });

    // تفريغ الحقول والعودة لصفحة المسح
    _barcodeController.clear();
    _nameController.clear();
    _unitPriceController.clear();
    _cartonPriceController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ السلعة في المخزن بنجاح!')),
    );
    setState(() {
      _currentIndex = 0; // العودة للماسح
    });
  }

  // فتح كارتون واحد
  void _openCarton() {
    if (_scannedProduct != null && _scannedProduct!.cartonStock > 0) {
      setState(() {
        _scannedProduct!.cartonStock -= 1;
        _scannedProduct!.singleStock += _scannedProduct!.itemsPerCarton;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم فتح كارتون وتحويله إلى قطع مفردة بنجاح!')),
      );
    }
  }

  // عملية البيع وطباعة الوصل
  void _sellItem(String type) async {
    if (_scannedProduct == null) return;

    double priceToCharge = 0;
    if (type == 'single') {
      if (_scannedProduct!.singleStock > 0) {
        _scannedProduct!.singleStock -= 1;
      } else if (_scannedProduct!.cartonStock > 0) {
        _scannedProduct!.cartonStock -= 1;
        _scannedProduct!.singleStock += (_scannedProduct!.itemsPerCarton - 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، المخزون نَفَد تماماً!')),
        );
        return;
      }
      priceToCharge = _scannedProduct!.unitPrice;
    } else {
      if (_scannedProduct!.cartonStock > 0) {
        _scannedProduct!.cartonStock -= 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد كارتونات متوفرة للبيع!')),
        );
        return;
      }
      priceToCharge = _scannedProduct!.cartonPrice;
    }

    // تسجيل البيع في السجل اليومي
    setState(() {
      _salesLog.insert(0, {
        'name': _scannedProduct!.name,
        'type': type == 'single' ? 'قطعة مفردة' : 'كارتون كامل',
        'price': priceToCharge,
        'time': DateTime.now().toString().substring(11, 19),
      });
    });

    // طباعة الوصل (عبر طابعة بلوتوث أو سلك USB المتصلة بالموبايل)
    await _printReceipt(_scannedProduct!.name, type, priceToCharge);
  }

  // طباعة الوصل الحراري
  Future<void> _printReceipt(String itemName, String type, double price) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('إيصال مبيعات المحل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('السلعة: $itemName'),
                pw.Text('النوع: $type'),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('السعر الإجمالي:'),
                pw.Text('$price د.ع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('شكراً لزيارتكم!', style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 1. صفحة الماسح والبيع
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MobileScanner(onDetect: _onBarcodeDetected),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () => setState(() { _lastScannedBarcode = ''; _scannedProduct = null; }),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة مسح باركود جديد'),
            ),
            const SizedBox(height: 15),
            if (_scannedProduct != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_scannedProduct!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [const Text('مفرد'), Text('${_scannedProduct!.unitPrice} د.ع', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))]),
                          Column(children: [const Text('كارتون'), Text('${_scannedProduct!.cartonPrice} د.ع', style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('القطع المفردة: ${_scannedProduct!.singleStock}'),
                          Text('الكارتونات: ${_scannedProduct!.cartonStock}'),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                          onPressed: _openCarton,
                          icon: const Icon(Icons.inventory_2),
                          label: Text('فتح كارتون واحد (+${_scannedProduct!.itemsPerCarton} قطعة)'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _sellItem('single'),
                              child: const Text('بيع مفرد'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => _sellItem('carton'),
                              child: const Text('بيع كارتون'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('وجه الكاميرا نحو باركود السلعة، أو انتقل لتبويب إضافة مادة جديدة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ],
        ),
      ),

      // 2. صفحة إضافة مادة جديدة
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة سلعة جديدة للمخزن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 15),
                TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'رقم الباركود', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم السلعة (مثال: بيبسي 300مل)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemsPerCartonController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'عدد القطع داخل الكارتون الواحد', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unitPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر القطعة المفردة', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cartonPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سعر الكارتون الكامل', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _singleStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'القطع المفردة الحالية', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cartonStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكارتونات الحالية', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: Colors.green,
                  ).wrap(
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: const Text('حفظ السلعة في المخزن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 3. صفحة جرد المبيعات اليومية
      ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _salesLog.length,
        itemBuilder: (context, index) {
          final sale = _salesLog[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              title: Text(sale['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('النوع: ${sale['type']} - الوقت: ${sale['time']}'),
              trailing: Text('${sale['price']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('برنامج الكاشير والمخازن الذكي'),
        centerTitle: true,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'الماسح والبيع'),
          NavigationDestination(icon: Icon(Icons.add_box), label: 'إضافة مادة'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'سجل المبيعات'),
        ],
      ),
    );
  }
}

extension on ButtonStyle? {
  Widget wrap(Widget child) => child;
}
