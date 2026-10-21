import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'sales_report_screen.dart';
import 'accounts_screen.dart';
import '../services/cloud_service.dart';

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

  void _handleCloudBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري رفع النسخة الاحتياطية للسحابة...'), duration: Duration(seconds: 1)),
    );
    bool success = await CloudService.uploadBackup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ تم رفع النسخة الاحتياطية بنجاح!' : '❌ فشل الرفع، تحقق من الإنترنت'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _handleCloudRestore(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري جلب ودمج البيانات من السحابة...'), duration: Duration(seconds: 1)),
    );
    bool success = await CloudService.downloadAndRestore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ تم دمج واستعادة البيانات بنجاح!' : '❌ فشل السحب من السحابة'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('نظام المبيعات والمخازن (${role == 'admin' ? 'مدير' : 'كاشير'})', style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 3, // تناسق ممتاز للهواتف والتابلت
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _buildMenuBtn(context, 'شاشة بيع', Icons.point_of_sale, const Color(0xFF38BDF8), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
              }),
              _buildMenuBtn(context, 'قائمة شراء', Icons.receipt_long_outlined, const Color(0xFF818CF8), () => _navigateToScreen(context, 'قائمة شراء')),
              _buildMenuBtn(context, 'عرض المواد', Icons.inventory_2_outlined, const Color(0xFFFB923C), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductListScreen()));
              }),
              _buildMenuBtn(context, 'إضافة مادة', Icons.add_box_outlined, const Color(0xFFF43F5E), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
              }),
              _buildMenuBtn(context, 'كشف مبيعات', Icons.shopping_cart_checkout, const Color(0xFFE11D48), () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesReportScreen()));
              }),
              _buildMenuBtn(context, 'إضافة حساب', Icons.person_add_alt_1_outlined, const Color(0xFFFACC15), () => _navigateToScreen(context, 'إضافة حساب')),
              _buildMenuBtn(context, 'سند قبض', Icons.receipt_sharp, const Color(0xFF4ADE80), () => _navigateToScreen(context, 'سند قبض')),
              _buildMenuBtn(context, 'أرصدة الحسابات', Icons.request_quote_outlined, const Color(0xFFF43F5E), () => _navigateToScreen(context, 'أرصدة الحسابات')),
              _buildMenuBtn(context, 'دمج السحابة', Icons.cloud_sync_outlined, const Color(0xFF34D399), () => _handleCloudRestore(context)),
              _buildMenuBtn(context, 'كشف حساب', Icons.badge_outlined, const Color(0xFFEC4899), () => _navigateToScreen(context, 'كشف حساب')),
              _buildMenuBtn(context, 'سند صرف', Icons.receipt_long, const Color(0xFF38BDF8), () => _navigateToScreen(context, 'سند صرف')),
              _buildMenuBtn(context, 'نسخ السحابة', Icons.cloud_upload_outlined, const Color(0xFFEF4444), () => _handleCloudBackup(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBtn(BuildContext context, String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2B45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
