import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('التقارير والأرباح المالية', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildReportCard('مبيعات اليوم', '125,000 د.ع', Icons.trending_up, const Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReportCard('عدد الفواتير', '18 فاتورة', Icons.receipt_long, const Color(0xFF0284C7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildReportCard('صافي الأرباح', '42,000 د.ع', Icons.savings, const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReportCard('المنتجات المباعة', '54 قطعة', Icons.shopping_bag, const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Card(
                color: Color(0xFF1E293B),
                child: Center(
                  child: Text(
                    '📈 رسم بياني لحركة المبيعات خلال الأسبوع\n(قيد التحديث والتطوير)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
