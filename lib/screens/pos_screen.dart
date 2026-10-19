import 'package:flutter/material.dart';
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

  // إضافة منتج للسلة
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

  // حساب المجموع الكلي
  double get _cartTotal {
    double total = 0;
    for (var item in _cart) {
      total += (item['price'] as double) * (item['cart_qty'] as double);
    }
    return total;
  }

  // إتمام عملية البيع
  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    try {
      await DatabaseHelper.instance.completeSale(_cart, _cartTotal);
      setState(() {
        _cart.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت عملية البيع بنجاح وتوليد الفاتورة!')),
      );
      _loadTouchProducts(); // تحديث المخزون
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Row(
        children: [
          // القسم الأيمن: أزرار اللمس للمنتجات
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _touchProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد مواد مضافة لعرضها في أزرار اللمس.\nقم بإضافة مواد جديدة وفعل خيار "إظهار في أزرار اللمس".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _touchProducts.length,
                          itemBuilder: (context, index) {
                            final product = _touchProducts[index];
                            return InkWell(
                              onTap: () => _addToCart(product),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product['name'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${product['price']} دينار',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'متوفر: ${product['quantity']}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
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

          // القسم الأيسر: سلة المبيعات والفاتورة
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade200,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('المادة', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('الكمية والسعر', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(
                            child: Text(
                              'السلة فارغة\nاختر مادة من الأزرار الجانبية',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return ListTile(
                                title: Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text('${item['price']} × ${item['cart_qty']}'),
                                trailing: Text(
                                  '${(item['price'] * item['cart_qty'])} د',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'المجموع: $_cartTotal دينار',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _checkout,
                          child: const Text('إتمام البيع والدفع', style: TextStyle(fontSize: 16, color: Colors.white)),
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
    );
  }
}
