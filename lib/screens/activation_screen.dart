import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activation_service.dart';
import 'admin_approval_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _loginController = TextEditingController(); // إيميل أو يوزر
  final TextEditingController _passController = TextEditingController();  // الرمز
  final TextEditingController _codeController = TextEditingController();  // كود التفعيل

  bool _isAccountCreated = false; 
  bool _isLoading = false;

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/9647862597668?text=${Uri.encodeComponent('السلام عليكم، قمت بتسجيل حساب باسم: ${_loginController.text} وأريد كود التفعيل.')}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الواتساب')));
    }
  }

  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://t.me/huzt92');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح التليجرام')));
    }
  }

  void _handleAction() async {
    if (!_formKey.currentState!.validate()) return;

    String loginInput = _loginController.text.trim();
    String passInput = _passController.text.trim();

    // 1. الدخول الخاص بك كأدمن ماستر
    if (loginInput == 'huzt.m1@gmail.com' && passInput == '20819921992') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
      );
      return;
    }

    // 2. الانتقال لصفحة إدخال كود التفعيل
    if (!_isAccountCreated) {
      setState(() {
        _isAccountCreated = true;
      });
      return;
    }

    // 3. معالجة إدخال كود التفعيل
    String activationCode = _codeController.text.trim();
    if (activationCode == '20319920') {
      setState(() => _isLoading = true);

      // حفظ بيانات الزبون الحقيقية محلياً وفي السحابة
      await ActivationService.savePendingUser(
        username: loginInput,
        email: loginInput.contains('@') ? loginInput : '$loginInput@client.com',
      );

      // إرسال الإشعار المباشر للتلغرام
      await ActivationService.sendTelegramActivationRequest(
        fullName: loginInput,
        email: loginInput.contains('@') ? loginInput : 'غير محدد',
        username: loginInput,
        phone: 'عبر التطبيق',
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.amber),
              SizedBox(width: 8),
              Text('طلب التفعيل', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'رجاءً انتظر موافقة المطور!\n\nتم إرسال طلبك بنجاح، وسيتم مراجعة الحساب وتفعيله فوراً.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ كود التفعيل غير صحيح!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 50, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 12),
                  Text(
                    _isAccountCreated ? 'تفعيل الحساب' : 'تسجيل حساب جديد',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (!_isAccountCreated) ...[
                    _buildField(_loginController, 'البريد الإلكتروني أو اسم المستخدم', Icons.person),
                    const SizedBox(height: 12),
                    _buildField(_passController, 'كلمة المرور', Icons.lock, isPassword: true),
                  ],

                  if (_isAccountCreated) ...[
                    _buildField(_codeController, 'أدخل كود التفعيل', Icons.vpn_key, isPassword: true),
                    const SizedBox(height: 16),
                    const Text('للحصول على كود التفعيل، يرجى التواصل مع المطور:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                            label: const Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088cc)),
                            onPressed: _openTelegram,
                            icon: const Icon(Icons.send, color: Colors.white, size: 18),
                            label: const Text('تليجرام', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      onPressed: _isLoading ? null : _handleAction,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isAccountCreated ? 'تفعيل الحساب' : 'التالي / تسجيل',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  // زر الرجوع المضاف حديثاً
                  if (_isAccountCreated) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAccountCreated = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white60, size: 16),
                      label: const Text('رجوع لتعديل البيانات', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
