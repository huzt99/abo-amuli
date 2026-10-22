import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _addNewProduct() async {
    String name = _nameController.text.trim();
    double? price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المنتج والسعر بشكل صحيح')),
      );
      return;
    }

    await DatabaseHelper.instance.insertProduct({
      'name': name,
      'price': price,
      'category': 'عام',
    });

    _nameController.clear();
    _priceController.clear();
    Navigator.pop(context);
    _loadProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة المنتج بنجاح')),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إضافة صنف / منتج جديد', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم المنتج', labelStyle: TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'السعر (د.ع)', labelStyle: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: _addNewProduct,
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إدارة المنتجات والأصناف', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: _products.isEmpty
          ? const Center(child: Text('لا توجد منتجات مضافة حالياً', style: TextStyle(color: Colors.white60)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                var p = _products[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.category, color: Color(0xFFF59E0B)),
                    title: Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('الفئة: ${p['category']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    trailing: Text('${p['price']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
