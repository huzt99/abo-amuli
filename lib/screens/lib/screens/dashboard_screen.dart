import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // قائمة الأزرار الـ 12 الرئيسية المطابقة لواجهة النظام الأصلية
    final List<Map<String, dynamic>> dashboardItems = [
      {'title': 'نقطة بيع', 'icon': Icons.point_of_sale, 'color': Colors.blueAccent},
      {'title': 'عرض المواد', 'icon': Icons.inventory, 'color': Colors.orangeAccent},
      {'title': 'إضافة مادة', 'icon': Icons.add_box, 'color': Colors.greenAccent},
      {'title': 'كشف مبيعات', 'icon': Icons.receipt_long, 'color': Colors.purpleAccent},
      {'title': 'إضافة حساب', 'icon': Icons.person_add, 'color': Colors.tealAccent},
      {'title': 'سند قبض', 'icon': Icons.call_received, 'color': Colors.indigoAccent},
      {'title': 'أرصدة الحسابات', 'icon': Icons.account_balance_wallet, 'color': Colors.amberAccent},
      {'title': 'قائمة شراء', 'icon': Icons.shopping_cart, 'color': Colors.cyanAccent},
      {'title': 'المطابقة اليومية', 'icon': Icons.balance, 'color': Colors.deepOrangeAccent},
      {'title': 'سند دفع', 'icon': Icons.call_made, 'color': Colors.redAccent},
      {'title': 'قائمة بيع', 'icon': Icons.list_alt, 'color': Colors.blueGrey},
      {'title': 'سند صرف', 'icon': Icons.money_off, 'color': Colors.brown},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // خلفية داكنة احترافية مطابقة للنظام
      appBar: AppBar(
        title: const Text('لوحة التحكم الرئيسية - نظام POS', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 أزرار في كل صف مثل الواجهة الأصلية
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: dashboardItems.length,
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return Card(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.withOpacity(0.2), width: 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // توجيه الشاشة حسب الزر المضغوط
                  if (item['title'] == 'نقطة بيع') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                  } else if (item['title'] == 'إضافة مادة') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم النقر على قسم: ${item['title']}', style: const TextStyle(fontFamily: 'Cairo'))),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
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
