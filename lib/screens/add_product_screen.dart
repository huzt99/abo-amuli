import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _isBarcodeMode = true; // true للمواد بالباركود، false للمواد بدون باركود
  
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _alertController = TextEditingController();

  // قوائم تاريخ الصلاحية المنسدلة
  int _selectedYear = 2026;
  int _selectedMonth = 1;
  int _selectedDay = 1;

  final List<int> _years = List.generate(35, (index) => 2026 + index); // من 2026 إلى 4060
  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _days = List.generate(31, (index) => index + 1);

  bool _isQuick = false;

  void _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _sellPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الحقول الأساسية (اسم المادة، الكمية، سعر البيع)')),
      );
    return;
    }

    String barcode = '';
    if (_isBarcodeMode) {
      barcode = _barcodeController.text.trim();
      if (barcode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال أو مسح الباركود للمادة')),
        );
        return;
      }
    } else {
      // توليد باركود تلقائي فريد للمواد بدون باركود
      barcode = 'NO_BC_${DateTime.now().millisecondsSinceEpoch}';
    }

    String expiryDate = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';

    Map<String, dynamic> row = {
      'barcode': barcode,
      'name': _nameController.text.trim(),
      'quantity': double.tryParse(_qtyController.text) ?? 0.0,
      'buy_price': double.tryParse(_buyPriceController.text) ?? 0.0,
      'sell_price': double.tryParse(_sellPriceController.text) ?? 0.0,
      'expiry_date': expiryDate,
      'alert_days': int.tryParse(_alertController.text) ?? 5,
      'is_quick': _isQuick ? 1 : 0,
    };

    try {
      await DatabaseHelper.instance.insertProduct(row);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المادة بنجاح في المخزن!'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إضافة منتج جديد للمخزن'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أزرار الاختيار بين بباركود أو بدون باركود
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isBarcodeMode = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBarcodeMode ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                    ),
                    child: const Text('مادة بباركود'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isBarcodeMode = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isBarcodeMode ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                    ),
                    child: const Text('مادة بدون باركود'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isBarcodeMode)
              _buildTextField(_barcodeController, 'باركود المادة (امسح أو اكتب الباركود)'),

            _buildTextField(_nameController, 'اسم المادة (مثال: طحين، سكر، بيبسي)'),
            _buildTextField(_qtyController, 'الكمية المتوفرة', isNumber: true),
            _buildTextField(_buyPriceController, 'سعر الشراء', isNumber: true),
            _buildTextField(_sellPriceController, 'سعر البيع للزبون', isNumber: true),

            const SizedBox(height: 10),
            const Text('تاريخ انتهاء الصلاحية:', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown('السنة', _selectedYear, _years, (val) => setState(() => _selectedYear = val!)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown('الشهر', _selectedMonth, _months, (val) => setState(() => _selectedMonth = val!)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown('اليوم', _selectedDay, _days, (val) => setState(() => _selectedDay = val!)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _buildTextField(_alertController, 'فترة التنبيه لانتهاء الصلاحية (بالأيام)', isNumber: true),

            CheckboxListTile(
              title: const Text('إظهار في أزرار اللمس السريعة', style: TextStyle(color: Colors.white)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: const Text('حفظ المادة في المخزن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, int value, List<int> items, ValueChanged<int?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          items: items.map((int item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text('$item'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
