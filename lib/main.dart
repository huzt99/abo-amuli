import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const SmartStoreApp());
}

class SmartStoreApp extends StatelessWidget {
  const SmartStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشير والمخازن الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.green,
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PosScreen(),
    const CameraScannerScreen(),
    const AddProductScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الكاشير والمخازن الذكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'نقطة البيع'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'الماسح الضوئي'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'إضافة مادة'),
        ],
      ),
    );
  }
}

// 1. شاشة نقطة البيع (متجاوبة للموبايل)
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  double total = 0.0;
  List<Map<String, dynamic>> cart = [];

  void addItem(String name, double price) {
    setState(() {
      cart.add({'name': name, 'price': price});
      total += price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // أزرار المواد السريعة
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickButton('بيبسي', 750),
                _quickButton('ماء', 250),
                _quickButton('شيبس', 500),
                _quickButton('عصير', 500),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // قائمة المنتجات بالفاتورة
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: cart.isEmpty
                  ? const Center(child: Text('السلة فارغة حالياً', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: const Color(0xFF2A2A2A),
                          child: ListTile(
                            title: Text(cart[index]['name']),
                            trailing: Text('${cart[index]['price']} د.ع', style: const TextStyle(color: Colors.greenAccent)),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // المجموع وزر البيع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المجموع الكلي:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$total د.ع', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: cart.isEmpty ? null : () {},
                  icon: const Icon(Icons.print),
                  label: const Text('حفظ وطباعة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _quickButton(String name, double price) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text('$name ($price)'),
        backgroundColor: Colors.indigo,
        labelStyle: const TextStyle(color: Colors.white),
        onPressed: () => addItem(name, price),
      ),
    );
  }
}

// 2. شاشة الماسح الضوئي
class CameraScannerScreen extends StatelessWidget {
  const CameraScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                debugPrint('Barcode found! ${barcode.rawValue}');
              }
            },
          ),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. شاشة إضافة مادة جديدة
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة مادة جديدة للمخزن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 16),
              _buildTextField('رقم الباركود', Icons.qr_code),
              _buildTextField('اسم المادة', Icons.shopping_bag),
              Row(
                children: [
                  Expanded(child: _buildTextField('سعر المفرد', Icons.attach_money)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('سعر الكارتون', Icons.inventory_2)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField('عدد القطع بالكارتون', Icons.format_list_numbered)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField('الكمية الحالية', Icons.numbers)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('حفظ المادة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
