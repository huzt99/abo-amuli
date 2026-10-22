import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // قائمة منتجات تجريبية للبيع
  final List<Map<String, dynamic>> _products = [
    {'id': 1, 'name': 'منتج 1', 'price': 5000, 'icon': Icons.shopping_bag},
    {'id': 2, 'name': 'منتج 2', 'price': 10000, 'icon': Icons.shopping_basket},
    {'id': 3, 'name': 'منتج 3', 'price': 15000, 'icon': Icons.fastfood},
    {'id': 4, 'name': 'منتج 4', 'price': 2500, 'icon': Icons.local_cafe},
  ];

  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index != -1) {
        _cart[index]['qty'] += 1;
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
  }

  double _getTotalPrice() {
    return _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // قسم عرض المنتجات
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                var p = _products[index];
                return InkWell(
                  onTap: () => _addToCart(p),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p['icon'], size: 36, color: const Color(0xFF38BDF8)),
                        const SizedBox(height: 8),
                        Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${p['price']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // قسم سلة المشتريات والفاتورة
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('الفاتورة الحالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        var item = _cart[index];
                        return ListTile(
                          title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                          subtitle: Text('العدد: ${item['qty']}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                          trailing: Text('${item['price'] * item['qty']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF0F172A),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المجموع:', style: TextStyle(color: Colors.white)),
                            Text('${_getTotalPrice()} د.ع', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: _cart.isEmpty
                              ? null
                              : () {
                                  setState(() => _cart.clear());
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إتمام البيع بنجاح')));
                                },
                          child: const Text('إتمام البيع', style: TextStyle(color: Colors.white)),
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
