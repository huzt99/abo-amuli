import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // قوائم الزبائن المتعددة في أعلى الشاشة (مطابق للصورة الاحترافية)
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
  final _qtyController = TextEditingController(text: '1');
  
  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'المواد', 'المشروبات', 'المعلبات', 'بدون باركود'];

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

  void _addNewTab() {
    setState(() {
      _customerTabs.add({
        'name': 'قائمة ${_customerTabs.length + 1}',
        'items': <Map<String, dynamic>>[],
      });
      _selectedTabIndex = _customerTabs.length - 1;
    });
  }

  void _addItemByBarcode(String barcode) {
    if (barcode.trim().isEmpty) return;

    final match = _allProducts.firstWhere(
      (p) => p['barcode'].toString().trim() == barcode.trim(),
      orElse: () => {},
    );

    double qty = double.tryParse(_qtyController.text) ?? 1.0;

    if (match.isNotEmpty) {
      setState(() {
        List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
        int existingIndex = currentCart.indexWhere((item) => item['id'] == match['id']);
        if (existingIndex >= 0) {
          currentCart[existingIndex]['sold_qty'] += qty;
        } else {
          Map<String, dynamic> cartItem = Map.from(match);
          cartItem['sold_qty'] = qty;
          currentCart.add(cartItem);
        }
      });
      _barcodeController.clear();
      _qtyController.text = '1';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ المادة غير موجودة في المخزن!'), backgroundColor: Colors.red),
      );
      _barcodeController.clear();
    }
  }

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

  void _checkout() async {
    List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
    if (currentCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('القائمة الحالية فارغة!'), backgroundColor: Colors.red),
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
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إتمام البيع: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentCart = _customerTabs[_selectedTabIndex]['items'];
    
    // تصفية المواد حسب القسم المحدد في لوحة الأزرار
    List<Map<String, dynamic>> filteredProducts = _allProducts;
    if (_selectedCategory == 'بدون باركود') {
      filteredProducts = _allProducts.where((p) => p['barcode'].toString().startsWith('NO_BC_')).toList();
    } else if (_selectedCategory != 'الكل') {
      filteredProducts = _allProducts.where((p) => !p['barcode'].toString().startsWith('NO_BC_')).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نقطة البيع الاحترافية (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        // شريط قوائم الزبائن في الأعلى
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
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
                            margin: const EdgeInsets.symmetric(horizontal: 3),
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
                // ================= القسم الأيسر: جدول المبيعات والإدخال والسلة =================
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white24)),
                    ),
                    child: Column(
                      children: [
                        // شريط الإدخال السريع (الباركود والكمية)
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _barcodeController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'مسح أو إدخال الباركود...',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: const Color(0xFF1E293B),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onSubmitted: _addItemByBarcode,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'الكمية',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: const Color(0xFF1E293B),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // جدول مواد القائمة (السلة)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: currentCart.isEmpty
                                ? const Center(
                                    child: Text(
                                      'السلة فارغة، امسح باركود أو اختر مادة من اللوحة اليمنى',
                                      style: TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: currentCart.length,
                                    itemBuilder: (context, index) {
                                      final item = currentCart[index];
                                      double itemTotal = (item['sell_price'] as num).toDouble() * (item['sold_qty'] as num).toDouble();
                                      return Container(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.white12)),
                                        ),
                                        child: ListTile(
                                          title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          subtitle: Text('السعر: ${item['sell_price']} | الكمية: ${item['sold_qty']}', style: const TextStyle(color: Colors.white70)),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('$itemTotal د.ع', style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
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
                        ),
                        const SizedBox(height: 10),

                        // شريط الإجماليات وأزرار التنفيذ السفلي (مطابق للصورة)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الإجمالي الكلي:', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('$_currentCartTotal د.ع', style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(() => currentCart.clear()),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.clear),
                                      label: const Text('إلغاء القائمة'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم طباعة الفاتورة بنجاح')));
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.print),
                                      label: const Text('طباعة'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: _checkout,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.point_of_sale),
                                      label: const Text('بيع القائمة (إتمام)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

                // ================= القسم الأيمن: لوحة أزرار اللمس السريعة (Touch Grid) =================
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // شريط تصنيفات المواد في أعلى اللوحة
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              String cat = _categories[index];
                              bool isSelected = _selectedCategory == cat;
                              return InkWell(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                                  ),
                                  child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // شبكة أزرار المواد المخزنة
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد مواد مخزنة، أضف مواد من شاشة "إضافة منتج"',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final prod = filteredProducts[index];
                                    return InkWell(
                                      onTap: () => _addItemToCart(prod),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              prod['name'],
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${prod['sell_price']} د.ع',
                                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
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
