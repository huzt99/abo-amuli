import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'sales_report_screen.dart';
import 'accounts_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String username;
  final String role;

  const DashboardScreen({
    super.key,
    this.username = 'المدير',
    this.role = 'admin',
  });

  void _navigateToScreen(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountsScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text('نظام المبيعات والمخازن (${role == 'admin' ? 'مدير' : 'كاشير'})'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                // 1. شاشة بيع
                _buildMenuBtn(
                  context,
                  title: 'شاشة بيع',
                  icon: Icons.point_of_sale,
                  iconColor: const Color(0xFF38BDF8),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                  },
                ),
                // 2. قائمة شراء
                _buildMenuBtn(
                  context,
                  title: 'قائمة شراء',
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFF818CF8),
                  onTap: () => _navigateToScreen(context, 'قائمة شراء'),
                ),
                // 3. عرض المواد
                _buildMenuBtn(
                  context,
                  title: 'عرض المواد',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFFB923C),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListScreen()));
                  },
                ),
                // 4. إضافة مادة
                _buildMenuBtn(
                  context,
                  title: 'إضافة مادة',
                  icon: Icons.add_box_outlined,
                  iconColor: const Color(0xFFF43F5E),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                  },
                ),
                // 5. كشف مبيعات
                _buildMenuBtn(
                  context,
                  title: 'كشف مبيعات',
                  icon: Icons.shopping_cart_checkout,
                  iconColor: const Color(0xFFE11D48),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesReportScreen()));
                  },
                ),
                // 6. إضافة حساب
                _buildMenuBtn(
                  context,
                  title: 'إضافة حساب',
                  icon: Icons.person_add_alt_1_outlined,
                  iconColor: const Color(0xFFFACC15),
                  onTap: () => _navigateToScreen(context, 'إضافة حساب'),
                ),
                // 7. سند قبض
                _buildMenuBtn(
                  context,
                  title: 'سند قبض',
                  icon: Icons.receipt_sharp,
                  iconColor: const Color(0xFF4ADE80),
                  onTap: () => _navigateToScreen(context, 'سند قبض'),
                ),
                // 8. أرصدة الحسابات
                _buildMenuBtn(
                  context,
                  title: 'أرصدة الحسابات',
                  icon: Icons.request_quote_outlined,
                  iconColor: const Color(0xFFF43F5E),
                  onTap: () => _navigateToScreen(context, 'أرصدة الحسابات'),
                ),
                // 9. دمج قاعدة البيانات
                _buildMenuBtn(
                  context,
                  title: 'دمج قاعدة البيانات',
                  icon: Icons.cloud_sync_outlined,
                  iconColor: const Color(0xFF34D399),
                  onTap: () => _navigateToScreen(context, 'دمج قاعدة البيانات'),
                ),
                // 10. كشف حساب
                _buildMenuBtn(
                  context,
                  title: 'كشف حساب',
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFFEC4899),
                  onTap: () => _navigateToScreen(context, 'كشف حساب'),
                ),
                // 11. سند صرف
                _buildMenuBtn(
                  context,
                  title: 'سند صرف',
                  icon: Icons.receipt_long,
                  iconColor: const Color(0xFF38BDF8),
                  onTap: () => _navigateToScreen(context, 'سند صرف'),
                ),
                // 12. قائمة بيع
                _buildMenuBtn(
                  context,
                  title: 'قائمة بيع',
                  icon: Icons.featured_play_list_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                  },
                ),
                // 13. سند دفع
                _buildMenuBtn(
                  context,
                  title: 'سند دفع',
                  icon: Icons.local_offer_outlined,
                  iconColor: const Color(0xFF4ADE80),
                  onTap: () => _navigateToScreen(context, 'سند دفع'),
                ),
                // 14. المطابقة اليومية
                _buildMenuBtn(
                  context,
                  title: 'المطابقة اليومية',
                  icon: Icons.crop_portrait_outlined,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => _navigateToScreen(context, 'المطابقة اليومية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBtn(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2B45),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: iconColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
