import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // دالة لجلب المواد من قاعدة البيانات
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  // دالة لحذف مادة
  Future<void> _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _loadProducts(); // إعادة تحميل القائمة بعد الحذف
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المادة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض وإدارة المواد المخزنة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مواد مخزنة حالياً.\nقم بإضافة مواد من شاشة "إضافة مادة".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            '${product['quantity']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                        ),
                        subtitle: Text(
                          'الباركود: ${product['barcode']} | سعر البيع: ${product['sale_price']} د.ع | الشراء: ${product['buy_price']} د.ع',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            // تأكيد الحذف
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف المادة', style: TextStyle(fontFamily: 'Cairo')),
                                content: Text('هل أنت متأكد من حذف (${product['name']})؟', style: const TextStyle(fontFamily: 'Cairo')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteProduct(product['id']);
                                    },
                                    child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
