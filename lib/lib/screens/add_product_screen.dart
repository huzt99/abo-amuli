import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // متحكمات الحقول
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _alertPeriodController = TextEditingController();

  bool _showInTouch = true; // خيار إظهار في اللمس

  // دالة الحفظ في قاعدة البيانات
  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> row = {
        'barcode': _barcodeController.text,
        'name': _nameController.text,
        'quantity': int.parse(_qtyController.text),
        'buy_price': double.parse(_buyPriceController.text),
        'sale_price': double.parse(_salePriceController.text),
        'expiry_date': _expiryDateController.text,
        'alert_period': int.tryParse(_alertPeriodController.text) ?? 0,
        'show_in_touch': _showInTouch ? 1 : 0,
      };

      try {
        await DatabaseHelper.instance.insertProduct(row);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المادة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: الباركود موجود مسبقاً أو بيانات غير صحيحة', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _barcodeController.clear();
    _nameController.clear();
    _qtyController.clear();
    _buyPriceController.clear();
    _salePriceController.clear();
    _expiryDateController.clear();
    _alertPeriodController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مادة جديدة للمخزن', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // حقل الباركود
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'الباركود (قم بالمسح أو الإدخال)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الباركود' : null,
              ),
              const SizedBox(height: 12),

              // اسم المادة
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المادة' : null,
              ),
              const SizedBox(height: 12),

              // العدد (الكمية)
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'العدد (الكمية المتوفرة)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الكمية' : null,
              ),
              const SizedBox(height: 12),

              // سعر الشراء وسعر البيع
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الشراء', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'أدخل سعر الشراء' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر البيع للزبون', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'أدخل سعر البيع' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // تاريخ انتهاء الصلاحية وفترة التنبيه
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(labelText: 'تاريخ انتهاء الصلاحية (Expiry)', border: OutlineInputBorder(), hintText: 'YYYY-MM-DD'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _alertPeriodController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'فترة التنبيه (بالأيام)', border: OutlineInputBorder(), hintText: 'مثلاً 10 أيام'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // خيار الإظهار في شاشة اللمس
              CheckboxListTile(
                title: const Text('إظهار في أزرار اللمس السريعة الرئيسية'),
                value: _showInTouch,
                onChanged: (bool? value) {
                  setState(() {
                    _showInTouch = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 24),

              // زر الحفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveProduct,
                child: const Text('حفظ المادة', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
