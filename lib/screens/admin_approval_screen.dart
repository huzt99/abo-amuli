import 'package:flutter/material.dart';
import '../services/activation_service.dart';
import 'activation_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  List<Map<String, dynamic>> pendingUsers = [];
  String rawDebugText = 'جاري الجلب...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    // جلب النتيجة مع النص الخام لفحصها
    final debugRes = await ActivationService.fetchCloudDebugResult();
    
    setState(() {
      pendingUsers = debugRes['users'] as List<Map<String, dynamic>>;
      rawDebugText = debugRes['raw'].toString();
      _isLoading = false;
    });
  }

  void _approveUser(String username) async {
    setState(() => _isLoading = true);
    await ActivationService.approveUserDual(username);
    await _loadUsers();
  }

  void _logoutAdmin() async {
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
        title: const Text('لوحة المطور - الفحص التشخيصي'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logoutAdmin,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // خانة التشخيص لعرض ما تقوله السحابة فعلياً
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مربع التشخيص (الاستجابة من سحابة JSONBin):', style: TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      child: Text(rawDebugText, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : pendingUsers.isEmpty
                      ? const Center(
                          child: Text('لا توجد طلبات تفعيل مسجلة حالياً في السحابة', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: pendingUsers.length,
                          itemBuilder: (context, index) {
                            final user = pendingUsers[index];
                            final isApproved = user['status'] == 'تم التفعيل ✅' || user['status'] == 'مفعل';

                            return Card(
                              color: const Color(0xFF1E2B45),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(user['username'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(user['status'] ?? 'معلق ⏳', style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.white24, height: 20),
                                    Text('🆔 المستخدم: ${user['username']}', style: const TextStyle(color: Colors.white70)),
                                    Text('📧 البريد: ${user['email']}', style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 12),
                                    if (!isApproved)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                          label: const Text('تفعيل الحساب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          onPressed: () => _approveUser(user['username']),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
