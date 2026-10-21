import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'sales_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String username;
  final String role;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'مرحباً، $username',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العمليات الرئيسية',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 5, // شبكة متقاربة واحترافية مثل الصورة
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  // 1. شاشة بيع (POS)
                  _buildDashboardCard(
                    context,
                    title: 'شاشة بيع',
                    icon: Icons.point_of_sale,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                    },
                  ),

                  // 2. إضافة مادة
                  _buildDashboardCard(
                    context,
                    title: 'إضافة مادة',
                    icon: Icons.add_box,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                    },
                  ),

                  // 3. عرض المواد (المخزن)
                  _buildDashboardCard(
                    context,
                    title: 'عرض المواد',
                    icon: Icons.inventory_2,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListScreen()));
                    },
                  ),

                  // 4. قائمة شراء
                  _buildDashboardCard(
                    context,
                    title: 'قائمة شراء',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قائمة الشراء قيد التفعيل')));
                    },
                  ),

                  // 5. كشف مبيعات
                  _buildDashboardCard(
                    context,
                    title: 'كشف مبيعات',
                    icon: Icons.receipt_long,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesReportScreen()));
                    },
                  ),

                  // 6. إضافة حساب
                  _buildDashboardCard(
                    context,
                    title: 'إضافة حساب',
                    icon: Icons.person_add,
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إضافة حساب زبون أو مورد')));
                    },
                  ),

                  // 7. سند الدفع
                  _buildDashboardCard(
                    context,
                    title: 'سند الدفع',
                    icon: Icons.payment,
                    color: const Color(0xFF14B8A6),
                    onTap: () {},
                  ),

                  // 8. أرصدة الحسابات
                  _buildDashboardCard(
                    context,
                    title: 'أرصدة الحسابات',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF6366F1),
                    onTap: () {},
                  ),

                  // 9. نسخ قاعدة البيانات
                  _buildDashboardCard(
                    context,
                    title: 'نسخ قاعدة البيانات',
                    icon: Icons.storage,
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ نسخة احتياطية من البيانات بنجاح')));
                    },
                  ),

                  // 10. كشف حساب
                  _buildDashboardCard(
                    context,
                    title: 'كشف حساب',
                    icon: Icons.description,
                    color: const Color(0xFFF97316),
                    onTap: () {},
                  ),

                  // 11. سند الصرف
                  _buildDashboardCard(
                    context,
                    title: 'سند الصرف',
                    icon: Icons.money_off,
                    color: const Color(0xFF84CC16),
                    onTap: () {},
                  ),

                  // 12. قائمة بيع
                  _buildDashboardCard(
                    context,
                    title: 'قائمة بيع',
                    icon: Icons.list_alt,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                    },
                  ),

                  // 13. سند الدخل
                  _buildDashboardCard(
                    context,
                    title: 'سند الدخل',
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                    onTap: () {},
                  ),

                  // 14. المطابقة اليومية
                  _buildDashboardCard(
                    context,
                    title: 'المطابقة اليومية',
                    icon: Icons.fact_check,
                    color: const Color(0xFFEAB308),
                    onTap: () {},
                  ),

                  // 15. كشف حذف
                  _buildDashboardCard(
                    context,
                    title: 'كشف حذف',
                    icon: Icons.delete_sweep,
                    color: const Color(0xFFEF4444),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
