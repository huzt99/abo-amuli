import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'sales_report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // خلفية هادئة وعصرية
      appBar: AppBar(
        title: const Text(
          'نظام المبيعات والمخازن POS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B), // أزرق داكن احترافي
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3, // 3 أعمدة تناسب الشاشات والموبايل
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildDashboardCard(
              context,
              title: 'نقطة بيع',
              icon: Icons.point_of_sale,
              color: const Color(0xFF2563EB), // أزرق ممتاز
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PosScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              title: 'إضافة منتج',
              icon: Icons.add_box_rounded,
              color: const Color(0xFF059669), // أخضر زاهي
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              title: 'قائمة المواد',
              icon: Icons.inventory_2,
              color: const Color(0xFFD97706), // برتقالي مريح
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductListScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              title: 'كشف مبيعات',
              icon: Icons.receipt_long,
              color: const Color(0xFF7C3AED), // بنفسجي ملفت
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesReportScreen()),
              ),
            ),
            _buildDashboardCard(
              context,
              title: 'عرض أردسة',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF475569),
            ),
            _buildDashboardCard(
              context,
              title: 'سند قبض',
              icon: Icons.download_rounded,
              color: const Color(0xFF0284C7),
            ),
            _buildDashboardCard(
              context,
              title: 'سند دفع',
              icon: Icons.upload_rounded,
              color: const Color(0xFFE11D48),
            ),
            _buildDashboardCard(
              context,
              title: 'سند صرف',
              icon: Icons.payments,
              color: const Color(0xFF4B5563),
            ),
            _buildDashboardCard(
              context,
              title: 'قائمة بيع',
              icon: Icons.shopping_bag,
              color: const Color(0xFF0891B2),
            ),
            _buildDashboardCard(
              context,
              title: 'المطابقة',
              icon: Icons.balance,
              color: const Color(0xFF65A30D),
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
