import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _touchProducts = [];
  final List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTouchProducts();
  }

  Future<void> _loadTouchProducts() async {
    final products = await DatabaseHelper.instance.getTouchProducts();
    setState(() {
      _touchProducts = products;
      _isLoading = false;
    });
  }

  Future<void> _scanAndAddBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;
    final allProducts = await DatabaseHelper.instance.getAllProducts();
    final product = allProducts.firstWhere(
      (p) => p['barcode'].toString().trim() == barcode.trim(),
      orElse: () => {},
    );

    if (product.isNotEmpty) {
      _addToCart(product);
      _barcodeController.clear();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المنتج بالباركود $barcode غير موجود بالمخزن!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              AppBar(
                title: const Text('وجّه الكاميرا نحو الباركود'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        final String code = barcode.rawValue!;
                        Navigator.pop(context);
                        _scanAndAddBarcode(code);
                        break;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['cart_qty'] += 1.0;
      } else {
        _cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'cart_qty': 1.0,
        });
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (var item in _cart) {
      total += (item['price'] as double) * (item['cart_qty'] as double);
    }
    return total;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    try {
      await DatabaseHelper.instance.completeSale(_cart, _cartTotal);
      setState(() {
        _cart.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت عملية البيع بنجاح وطباعة الفاتورة!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTouchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نقطة البيع السريع (POS)', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.greenAccent, size: 28),
            onPressed: _openCameraScanner,
            tooltip: 'فحص باركود بالكاميرا',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث وفحص الباركود السريع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'امسح أو اكتب الباركود هنا...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.barcode_reader, color: Colors.blueAccent),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (value) => _scanAndAddBarcode(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _openCameraScanner,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // أزرار اللمس للمنتجات
                Expanded(
                  flex: 3,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                      : _touchProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'لا توجد مواد مضافة لأزرار اللمس.\nأضف مواد من شاشة "إضافة منتج" وفعل خيار الإظهار.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: _touchProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _touchProducts[index];
                                  return InkWell(
                                    onTap: () => _addToCart(product),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${product['price']} د.ع',
                                            style: const TextStyle(
                                              color: Color(0xFF34D399),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),

                // سلة المبيعات
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      border: Border(right: BorderSide(color: Color(0xFF334155))),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFF0F172A),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('سلة المبيعات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Icon(Icons.shopping_cart_outlined, color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _cart.isEmpty
                              ? Center(
                                  child: Text(
                                    'السلة فارغة',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final item = _cart[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      subtitle: Text('${item['price']} × ${item['cart_qty']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      trailing: Text(
                                        '${(item['price'] * item['cart_qty'])} د',
                                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFF0F172A),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('$_cartTotal د.ع', style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _checkout,
                                child: const Text('إتمام البيع', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
