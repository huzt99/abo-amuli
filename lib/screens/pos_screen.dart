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
      ),
      body: Row(
        children: [
          // القسم الأيمن: أزرار المنتجات بتصميم عصري فخم
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
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _touchProducts.length,
                          itemBuilder: (context, index) {
                            final product = _touchProducts[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _addToCart(product),
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
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
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'المخزون: ${product['quantity']}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // القسم الأيسر: سلة المبيعات الاحترافية
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
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF0F172A),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('سلة المبيعات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Icon(Icons.shopping_cart_outlined, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cart.isEmpty
                        ? Center(
                            child: Text(
                              'السلة فارغة\nاضغط على المنتجات لبيعها',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return ListTile(
                                title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text('${item['price']} × ${item['cart_qty']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                trailing: Text(
                                  '${(item['price'] * item['cart_qty'])} د',
                                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF0F172A),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المجموع الكلي:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('$_cartTotal دينار', style: const TextStyle(color: Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _checkout,
                          child: const Text('إتمام البيع والدفع', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
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
