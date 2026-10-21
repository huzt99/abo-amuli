import 'package:flutter/material.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  List<Map<String, String>> pendingUsers = [
    {
      'name': 'محل زبون جديد',
      'username': 'client_pos1',
      'email': 'client@gmail.com',
      'phone': '07800000000',
      'status': 'معلق ⏳',
    }
  ];

  void _approveUser(int index) {
    setState(() {
      pendingUsers[index]['status'] = 'تم التفعيل ✅';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم قبول وتفعيل حساب ${pendingUsers[index]['username']} بنجاح!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('لوحة المطور - إدارة طلبات التفعيل'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: pendingUsers.isEmpty
            ? const Center(
                child: Text('لا توجد طلبات تفعيل معلقة حالياً', style: TextStyle(color: Colors.white70, fontSize: 16)),
              )
            : ListView.builder(
                itemCount: pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  final isApproved = user['status'] == 'تم التفعيل ✅';

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
                              Text(user['name']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(user['status']!, style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 20),
                          Text('🆔 اسم المستخدم: ${user['username']}', style: const TextStyle(color: Colors.white70)),
                          Text('📧 البريد الإلكتروني: ${user['email']}', style: const TextStyle(color: Colors.white70)),
                          Text('📞 رقم الهاتف: ${user['phone']}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          if (!isApproved)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text('تفعيل الحساب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () => _approveUser(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
