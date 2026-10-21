import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // إنشاء 10 قوائم افتراضية للزبائن
  final List<String> _customerLists = List.generate(10, (index) => 'قائمة بيع رقم ${index + 1}');

  void _addNewList() {
    setState(() {
      _customerLists.add('قائمة بيع رقم ${_customerLists.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نقطة البيع (اختر قائمة الزبون)'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
            onPressed: _addNewList,
            tooltip: 'إضافة قائمة جديدة',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _customerLists.length,
          itemBuilder: (context, index) {
            final listName = _customerLists[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerCartScreen(listName: listName),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    Text(
                      listName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'اضغط للفتح والبيع',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// نافذة القائمة الخاصة بالزبون (تحتوي على الباركود والمواد بدون باركود وإتمام البيع)
class CustomerCartScreen extends StatefulWidget {
  final String listName;
  const CustomerCartScreen({super.key, required this.listName});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final _barcodeController = TextEditingController();
  final List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreProducts();
  }

  void _loadStoreProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _allProducts = products;
      _isLoading = false;
    });
  }

  void _addItemByBarcode(String barcode) async {
    if (barcode.isEmpty) return;
    final match = _allProducts.firstWhere(
      (p) => p['barcode'].toString().trim() == barcode.trim(),
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      setState(() {
        int existingIndex = _cartItems.indexWhere((item) => item['id'] == match['id']);
        if (existingIndex >= 0) {
          _cartItems[existingIndex]['sold_qty'] += 1.0;
        } else {
          Map<String, dynamic> cartItem = Map.from(match);
          cartItem['sold_qty'] = 1.0;
          _cartItems.add(cartItem);
        }
      });
      _barcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المادة غير موجودة في المخزن'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNoBarcodeDialog() {
    final noBcProducts = _allProducts.where((p) => p['barcode'].toString().startsWith('NO_BC_')).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('اختر مادة بدون باركود', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: noBcProducts.isEmpty
                ? const Text('لا توجد مواد بدون باركود مضافة', style: TextStyle(color: Colors.white54))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: noBcProducts.length,
                    itemBuilder: (context, index) {
                      final product = noBcProducts[index];
                      return ListTile(
                        title: Text(product['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text('السعر: ${product['sell_price']} دينار', style: const TextStyle(color: Colors.greenAccent)),
                        trailing: ElevatedButton(
                          child: const Text('إضافة'),
                          onPressed: () {
                            setState(() {
                              int existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);
                              if (existingIndex >= 0) {
                                _cartItems[existingIndex]['sold_qty'] += 1.0;
                              } else {
                                Map<String, dynamic> cartItem = Map.from(product);
                                cartItem['sold_qty'] = 1.0;
                                _cartItems.add(cartItem);
                              }
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  double get _totalAmount {
    double total = 0;
    for (var item in _cartItems) {
      double price = (item['sell_price'] as num).toDouble();
      double qty = (item['sold_qty'] as num).toDouble();
      total += price * qty;
    }
    return total;
  }

  void _checkoutList() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('القائمة فارغة'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.completeSale(_cartItems, _totalAmount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم البيع بنجاح وحفظ القائمة (${widget.listName})!'), backgroundColor: Colors.green),
      );
      setState(() {
        _cartItems.clear();
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إتمام البيع: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.listName),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'امسح أو اكتب الباركود هنا',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onSubmitted: _addItemByBarcode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showNoBarcodeDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        child: const Text('بدون باركود'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? const Center(child: Text('السلة فارغة، أضف مواد للبيع', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return Card(
                                color: const Color(0xFF1E293B),
                                child: ListTile(
                                  title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text('الكمية المباعة: ${item['sold_qty']} | السعر: ${item['sell_price']} د.ع', style: const TextStyle(color: Colors.white70)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => setState(() => _cartItems.removeAt(index)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع الكلي: $_totalAmount د.ع', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: _checkoutList,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        child: const Text('بيع القائمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
