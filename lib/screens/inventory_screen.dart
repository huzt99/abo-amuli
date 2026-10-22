import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'منتج 1', 'qty': 45, 'minLimit': 5},
    {'name': 'منتج 2', 'qty': 12, 'minLimit': 10},
    {'name': 'منتج 3', 'qty': 3, 'minLimit': 5}, // تحت الحد الأدنى
    {'name': 'منتج 4', 'qty': 25, 'minLimit': 8},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إدارة المخزن والمخزون', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inventory.length,
        itemBuilder: (context, index) {
          var item = _inventory[index];
          bool isLow = item['qty'] <= item['minLimit'];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isLow ? Colors.redAccent : Colors.transparent, width: 1.5),
            ),
            child: ListTile(
              leading: Icon(Icons.inventory_2, color: isLow ? Colors.redAccent : const Color(0xFF10B981)),
              title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isLow ? '⚠️ تنبيه: الكمية منخفضة جداً!' : 'المخزون متوفر بكفاية',
                style: TextStyle(color: isLow ? Colors.redAccent : Colors.white60, fontSize: 11),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLow ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'العدد: ${item['qty']}',
                  style: TextStyle(color: isLow ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
