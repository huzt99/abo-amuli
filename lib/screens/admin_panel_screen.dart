import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/activation_service.dart';
import 'activation_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  void _fetchRequests() async {
    setState(() => _isLoading = true);
    var list = await ActivationService.getPendingRequests();
    setState(() {
      _requests = list;
      _isLoading = false;
    });
  }

  void _approveAndGenerateCode(String phone) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري توليد كود التفعيل المكون من 11 رقم...')));
    String? code = await ActivationService.approveUserAndGenerateCode(phone);
    
    if (code != null) {
      _fetchRequests();
      _showCodeDialog(phone, code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التفعيل')));
    }
  }

  void _showCodeDialog(String phone, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تم التفعيل وتوليد الرمز', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم العميل: $phone', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('كود التفعيل (11 رقم):', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 6),
            SelectableText(
              code,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود التفعيل')));
            },
            child: const Text('نسخ الكود', style: TextStyle(color: Color(0xFF10B981))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await ActivationService.setAdminLoggedIn(false);
    if (!mounted) return;
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
        title: const Text('لوحة الأدمن - إدارة طلبات التفعيل', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : RefreshIndicator(
              onRefresh: () async => _fetchRequests(),
              child: _requests.isEmpty
                  ? const Center(child: Text('لا توجد طلبات تفعيل حالياً', style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        var req = _requests[index];
                        bool isApproved = req['status'] == 'approved';
                        String code = req['activation_code'] ?? '';

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(req['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('الهاتف: ${req['phone']}', style: const TextStyle(color: Colors.white70)),
                                if (isApproved)
                                  Text('الكود: $code', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: isApproved
                                ? const Chip(
                                    label: Text('مفعل', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Color(0xFF10B981),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                                    onPressed: () => _approveAndGenerateCode(req['phone']),
                                    child: const Text('موافقة وتوليد كود', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
