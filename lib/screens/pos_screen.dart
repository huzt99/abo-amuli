import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _touchProducts = [];
  final List<Map<String, dynamic>> cartItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTouchProducts();
  }

  // جلب المواد المخزنة والتي تظهر في اللمس من قاعدة البيانات
  Future<void> _loadTouchProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _touchProducts = products.where((p) => p['show_in_touch'] == 1).toList();
    });
  }

  // إضافة المادة إلى سلة المبيعات عند النقر عليها
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int index = cartItems.indexWhere((item) => item['id'] == product['id']);
      if (index != -1) {
        cartItems[index]['qty'] += 1;
        cartItems[index]['total'] = cartItems[index]['qty'] * cartItems[index]['sale_price'];
      } else {
        cartItems.add({
          'id': product['id'],
          'name': product['name'],
          'qty': 1,
          'sale_price': product['sale_price'],
          'total': product['sale_price'],
        });
      }
      _calculateTotal();
    });
  }

  // حساب المجموع الكلي للفاتورة
  void _calculateTotal() {
    _totalAmount = 0.0;
    for (var item in cartItems) {
      _totalAmount += item['total'];
    }
  }

  // حذف مادة من السلة
  void _removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ==========================================
          // القسم الأيسر: سلة المبيعات، الفاتورة، وأزرار التحكم
          // ==========================================
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // شريط معلومات الزبون والمخزن العلوي
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: const Color(0xFFE2E8F0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.store, size: 20),
                            SizedBox(width: 8),
                            Text('مخزن 1', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text('زبون نقدي', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),

                  // قائمة المواد المضافة للفاتورة
                  Expanded(
                    child: cartItems.isEmpty
                        ? const Center(
                            child: Text(
                              'السلة فارغة\nاختر مادة من الأزرار الجانبية',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          )
                        : ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: ListTile(
                                  leading: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _removeFromCart(index),
                                  ),
                                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                  subtitle: Text('العدد: ${item['qty']} | السعر: ${item['sale_price']} د.ع', style: const TextStyle(fontFamily: 'Cairo')),
                                  trailing: Text('${item['total']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontFamily: 'Cairo')),
                                ),
                              );
                            },
                          ),
                  ),

                  // شريط إجمالي الفاتورة
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF0F172A),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مجموع القائمة', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
                        Text('$_totalAmount دينار', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),

                  // أزرار التحكم السفلية
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        _buildBottomActionButton('إلغاء', const Color(0xFFEF4444), () {
                          setState(() {
                            cartItems.clear();
                            _calculateTotal();
                          });
                        }),
                        _buildBottomActionButton('طباعة', const Color(0xFF475569), () {}),
                        _buildBottomActionButton('طريقة دفع', const Color(0xFF0284C7), () {}),
                        _buildBottomActionButton('إرجاع بيع', const Color(0xFF3B82F6), () {}),
                        
                        // زر بيع المحدث والمربوط بقاعدة البيانات
                        _buildBottomActionButton('بيع', const Color(0xFF2563EB), () async {
                          if (cartItems.isNotEmpty) {
                            await DatabaseHelper.instance.insertInvoice({
                              'total_amount': _totalAmount,
                              'date_time': DateTime.now().toString().substring(0, 19),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إتمام البيع وحفظ الفاتورة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
                            );
                            setState(() {
                              cartItems.clear();
                              _calculateTotal();
                            });
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // القسم الأيمن: أزرار المواد السريعة
          // ==========================================
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Container(
                  height: 55,
                  color: const Color(0xFF1E293B),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'أزرار المواد السريعة (تظهر المواد المضافة تلقائياً)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: _touchProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد مواد مضافة لعرضها في أزرار اللمس.\nقم بإضافة مواد جديدة من لوحة التحكم.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: _touchProducts.length,
                            itemBuilder: (context, index) {
                              final product = _touchProducts[index];
                              return Card(
                                color: const Color(0xFF1E293B),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  onTap: () => _addToCart(product),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        '${product['name']}\n(${product['sale_price']} د.ع)',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Widget _buildBottomActionButton(String title, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
