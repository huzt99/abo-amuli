import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // قوائم الزبائن المتعددة في أعلى الشاشة (مثل الصورة الاحترافية)
  final List<Map<String, dynamic>> _customerTabs = List.generate(
    10,
    (index) => {
      'name': 'قائمة ${index + 1}',
      'items': <Map<String, dynamic>>[],
    },
  );

  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // إضافة قائمة جديدة بضغطة زر
  void _addNewTab() {
    setState(() {
      _customerTabs.add({
        'name': 'قائمة ${_customerTabs.length + 1}',
        'items': <Map<String, dynamic>>[],
      });
      _selectedTabIndex = _customerTabs.length - 1;
    });
  }

  // إضافة مادة للسلة الحالية عن طريق الباركود
  void _addItemByBarcode(String barcode) {
    if (barcode.trim().isEmpty) return;

    final match = _allProducts.firstWhere(
      (p) => p['barcode'].toString().trim() == barcode.trim(),
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      setState(() {
        List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
        int existingIndex = currentCart.indexWhere((item) => item['id'] == match['id']);
        if (existingIndex >= 0) {
          currentCart[existingIndex]['sold_qty'] += 1.0;
        } else {
          Map<String, dynamic> cartItem = Map.from(match);
          cartItem['sold_qty'] = 1.0;
          currentCart.add(cartItem);
        }
      });
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ المادة غير موجودة في المخزن!'), backgroundColor: Colors.red),
      );
      _barcodeController.clear();
    }
  }

  // إضافة مادة بالسلطة مباشرة عند الضغط على زر اللمس
  void _addItemToCart(Map<String, dynamic> product) {
    setState(() {
      List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
      int existingIndex = currentCart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex >= 0) {
        currentCart[existingIndex]['sold_qty'] += 1.0;
      } else {
        Map<String, dynamic> cartItem = Map.from(product);
        cartItem['sold_qty'] = 1.0;
        currentCart.add(cartItem);
      }
    });
  }

  // حساب المجموع الكلي للقائمة الحالية
  double get _currentCartTotal {
    double total = 0;
    List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
    for (var item in currentCart) {
      double price = (item['sell_price'] as num).toDouble();
      double qty = (item['sold_qty'] as num).toDouble();
      total += price * qty;
    }
    return total;
  }

  // إتمام البيع وحفظ الفاتورة
  void _checkout() async {
    List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
    if (currentCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        constSnackBar(content: Text('القائمة الحالية فارغة!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.completeSale(currentCart, _currentCartTotal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم بيع (${_customerTabs[_selectedTabIndex]['name']}) بنجاح!'), backgroundColor: Colors.green),
      );
      setState(() {
        currentCart.clear();
      });
      _loadProducts(); // تحديث المخزن والكميات
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إتمام البيع: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
    // تصفية المواد بدون باركود والمواد العادية لعرضها بالأزرار السريعة
    final quickProducts = _allProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نقطة البيع الاحترافية (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        // شريط قوائم الزبائن في الأعلى (مثل الصورة)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _customerTabs.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedTabIndex == index;
                        return InkWell(
                          onTap: () => setState(() => _selectedTabIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                            ),
                            child: Text(
                              _customerTabs[index]['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Color(0xFF10B981), size: 28),
                  onPressed: _addNewTab,
                  tooltip: 'إضافة قائمة جديدة',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // ----------------- القسم الأيسر: سلة المبيعات والفاتورة -----------------
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white24)),
                    ),
                    child: Column(
                      children: [
                        // خانة إدخال الباركود السريع
                        TextField(
                          controller: _barcodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'مسح أو إدخال الباركود هنا...',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF3B82F6)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onSubmitted: _addItemByBarcode,
                        ),
                        const SizedBox(height: 10),

                        // جدول مواد السلة
                        Expanded(
                          child: currentCart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'السلة فارغة، امسح الباركود أو اختر مادة من لوحة الأزرار يمين الشاشة',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: currentCart.length,
                                  itemBuilder: (context, index) {
                                    final item = currentCart[index];
                                    double itemTotal = (item['sell_price'] as num).toDouble() * (item['sold_qty'] as num).toDouble();
                                    return Card(
                                      color: const Color(0xFF1E293B),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      child: ListTile(
                                        title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        subtitle: Text('السعر: ${item['sell_price']} | الكمية: ${item['sold_qty']}', style: const TextStyle(color: Colors.white70)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('$itemTotal د.ع', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                              onPressed: () => setState(() => currentCart.removeAt(index)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // شريط المجموع وأزرار التنفيذ بالأسفل
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع الكلي:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  Text('$_currentCartTotal د.ع', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(() => currentCart.clear()),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      icon: const Icon(Icons.clear_all),
                                      label: const Text('إفراغ القائمة'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: _checkout,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.point_of_sale),
                                      label: const Text('بيع القائمة (إتمام)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ----------------- القسم الأيمن: لوحة أزرار اللمس للمواد (Touch Grid) -----------------
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لوحة المواد السريعة (اضغط للإضافة الفورية):',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: quickProducts.isEmpty
                              .toString() == 'true' && quickProducts.isEmpty
                              ? const Center(child: Text('لا توجد مواد مخزنة حالياً، أضف مواد من شاشة إضافة منتج', style: TextStyle(color: Colors.white54)))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemCount: quickProducts.length,
                                  itemBuilder: (context, index) {
                                    final prod = quickProducts[index];
                                    return InkWell(
                                      onTap: () => _addItemToCart(prod),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              prod['name'],
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${prod['sell_price']} د.ع',
                                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'الخزين: ${prod['quantity']}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
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
    );
  }
}
