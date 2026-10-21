import 'package:flutter/material.dart';
import '../services/activation_service.dart';
import 'activation_screen.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  void _logout(BuildContext context) async {
    await ActivationService.setLocalActivated(false);
    await ActivationService.setAdminLoggedIn(false);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ActivationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('نظام المبيعات والمخازن - الرئيسية', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _logout(context),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.point_of_sale, size: 40, color: Color(0xFF38BDF8)),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أهلاً بك', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('النسخة مفعلة وجاهزة للعمل بكفاءة', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('الأقسام الرئيسية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildDashboardCard(
                    title: 'نقطة البيع (POS)',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF0284C7),
                    onTap: () => _showMsg(context, 'تم فتح شاشة المبيعات'),
                  ),
                  _buildDashboardCard(
                    title: 'إدارة المخزن',
                    icon: Icons.inventory_2,
                    color: const Color(0xFF10B981),
                    onTap: () => _showMsg(context, 'تم فتح إدارة المخازن'),
                  ),
                  _buildDashboardCard(
                    title: 'المنتجات والأصناف',
                    icon: Icons.category,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _showMsg(context, 'تم فتح قائمة المنتجات'),
                  ),
                  _buildDashboardCard(
                    title: 'التقارير والأرباح',
                    icon: Icons.bar_chart,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _showMsg(context, 'تم فتح التقارير'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }
}
