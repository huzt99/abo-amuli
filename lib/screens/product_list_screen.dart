import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _barcodeProducts = [];
  List<Map<String, dynamic>> _noBarcodeProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
  }

  void _loadProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _barcodeProducts = products.where((p) => !p['barcode'].toString().startsWith('NO_BC_')).toList();
      _noBarcodeProducts = products.where((p) => p['barcode'].toString().startsWith('NO_BC_')).toList();
      _isLoading = false;
    });
  }

  void _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إدارة المخزن والمواد'),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'المواد بباركود'),
            Tab(text: 'المواد بدون باركود'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_barcodeProducts),
                _buildProductList(_noBarcodeProducts),
              ],
            ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      const Center(
        child: Text('لا توجد مواد مخزنة حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        bool isLowStock = (product['quantity'] as double) <= 5.0; // تنبيه قرب نفاد الكمية

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLowStock ? Colors.redAccent : Colors.white12,
              width: isLowStock ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              product['name'],
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('الكمية المتوفرة: ${product['quantity']} أعداد/كيلو', style: const TextStyle(color: Colors.white70)),
                Text('سعر البيع: ${product['sell_price']} دينار', style: const TextStyle(color: Color(0xFF10B981))),
                if (isLowStock)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text('⚠️ تنبيه: الكمية على وشك النفاد!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteProduct(product['id']),
            ),
          ),
        );
      },
    );
  }
}
