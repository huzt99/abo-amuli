import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllInvoices();
    setState(() {
      _invoices = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // حساب إجمالي المبيعات الكلية
    double totalSalesSum = 0;
    for (var inv in _invoices) {
      totalSalesSum += (inv['total_amount'] ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف المبيعات والتقارير', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // لوحة إجمالي المبيعات في الأعلى
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي المبيعات الكلية:', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
                Text('$totalSalesSum دينار', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                .printEmptyState() // helper fallback check or direct boolean:
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد فواتير مبيعات مسجلة حتى الآن.\nقم بإتمام عمليات بيع من شاشة "نقطة بيع".',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final inv = _invoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB),
                                child: Text('${inv['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('رقم الفاتورة: #${inv['id']} | المجموع: ${inv['total_amount']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                              subtitle: Text('التاريخ والوقت: ${inv['date_time']}', style: const TextStyle(fontFamily: 'Cairo')),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Extension helper
extension on bool {
  bool printEmptyState() => this;
}
