import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'sales_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String username;
  final String role; // 'admin' أو 'cashier'

  const DashboardScreen({
    super.key,
    this.username = 'المدير',
    this.role = 'admin',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('نظام المبيعات والمخازن (${role == 'admin' ? 'مدير' : 'كاشير'})'),
        backgroundColor: const Color(0xFF1E293B),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              // العودة لتسجيل الدخول أو الخروج
              Navigator.pop(context);
            },
            tooltip: 'خروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, size: 40, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك، $username',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == 'admin' ? 'صلاحيات كاملة لإدارة النظام' : 'صلاحيات مخصصة للبيع السريع فقط',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'العمليات الرئيسية',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // نقطة البيع (متاحة للجميع)
                  _buildMenuCard(
                    context,
                    title: 'نقطة بيع (POS)',
                    subtitle: 'شاشة البيع السريع',
                    icon: Icons.point_of_sale,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PosScreen()),
                      );
                    },
                  ),

                  // إضافة منتج (للمدير فقط أو مع صلاحية)
                  _buildMenuCard(
                    context,
                    title: 'إضافة منتج',
                    subtitle: 'إدخال مادة جديدة للمخزن',
                    icon: Icons.add_box,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddProductScreen()),
                      );
                    },
                  ),

                  // قائمة المواد (المخزن والكميات)
                  _buildMenuCard(
                    context,
                    title: 'قائمة المواد',
                    subtitle: 'إدارة المخزن والكميات',
                    icon: Icons.inventory_2,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductListScreen()),
                      );
                    },
                  ),

                  // كشف المبيعات (التقارير والأرباح - محمية أو مخصصة)
                  _buildMenuCard(
                    context,
                    title: 'كشف المبيعات',
                    subtitle: 'تقارير الفواتير والأرباح',
                    icon: Icons.receipt_long,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
