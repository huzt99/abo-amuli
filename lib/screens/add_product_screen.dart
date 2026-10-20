import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _expiryController = TextEditingController();
  final _alertController = TextEditingController();
  bool _isQuick = false;

  void _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _sellPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المادة والكمية وسعر البيع')),
      );
      return;
    }

    // معالجة الباركود التلقائي للمواد التي بدون باركود (مثل الطحين والسكر والكرزات)
    String barcode = _barcodeController.text.trim();
    if (barcode.isEmpty || barcode.contains('بدون')) {
      barcode = 'NO_BC_${DateTime.now().millisecondsSinceEpoch}';
    }

    Map<String, dynamic> row = {
      'barcode': barcode,
      'name': _nameController.text.trim(),
      'quantity': double.tryParse(_qtyController.text) ?? 0.0,
      'buy_price': double.tryParse(_buyPriceController.text) ?? 0.0,
      'sell_price': double.tryParse(_sellPriceController.text) ?? 0.0,
      'expiry_date': _expiryController.text.trim(),
      'alert_days': int.tryParse(_alertController.text) ?? 0,
      'is_quick': _isQuick ? 1 : 0,
    };

    try {
      await DatabaseHelper.instance.insertProduct(row);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المادة بنجاح وإضافتها للمخزن!'),
          backgroundColor: Colors.green,
        ),
      );

      // تفريغ الحقول التلقائي بعد الحفظ
      _barcodeController.clear();
      _nameController.clear();
      _qtyController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _expiryController.clear();
      _alertController.clear();
      setState(() => _isQuick = false);

      // العودة للشاشة الرئيسية لتحديث القوائم
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إضافة مادة جديدة للمخزن'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_barcodeController, 'الباركود (اتركه فارغاً إذا كانت المادة بدون باركود)'),
            _buildTextField(_nameController, 'اسم المادة (مثال: طحين، سكر، تمن)'),
            _buildTextField(_qtyController, 'العدد / الكمية (مثال: 80 كيلو أو قطعة)', isNumber: true),
            _buildTextField(_buyPriceController, 'سعر الشراء', isNumber: true),
            _buildTextField(_sellPriceController, 'سعر البيع للزبون', isNumber: true),
            _buildTextField(_expiryController, 'تاريخ انتهاء الصلاحية (YYYY-MM-DD)'),
            _buildTextField(_alertController, 'فترة التنبيه بالبلوم (أيام)', isNumber: true),
            CheckboxListTile(
              title: const Text('إظهار في أزرار اللمس السريعة الرئيسية', style: TextStyle(color: Colors.white)),
              value: _isQuick,
              onChanged: (val) => setState(() => _isQuick = val ?? false),
              activeColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                child: const Text('حفظ المادة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.slate),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
