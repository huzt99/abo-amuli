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
  
  // حقول الإدخال بالترتيب المطلوب
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  // فتح رابط الواتساب المباشر
  Future<void> _openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/9647862597668?text=${Uri.encodeComponent('السلام عليكم، قمت بإرسال طلب تفعيل للبرنامج، اسم المستخدم: ${_usernameController.text}')}');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  // فتح معرف التليجرام المباشر
  Future<void> _openTelegram() async {
    final Uri telegramUrl = Uri.parse('https://t.me/huzt92');
    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _submitActivation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String phone = _phoneController.text.trim();
    String code = _codeController.text.trim();

    // 1. دخول حساب الأدمن الماستر الخاص بك
    if (email == 'huzt.m1@gmail.com' && (code == '20819921992' || code == '20319920')) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
      );
      return;
    }

    // 2. كود التفعيل الموحد للزبائن
    if (code == '20319920') {
      // إرسال الإشعار للتلغرام الخاص بك
      await ActivationService.sendTelegramActivationRequest(
        fullName: name,
        email: email,
        username: username,
        phone: phone,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // إظهار نافذة الانتظار ومراجعة المطور
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
              Text('الطلب قيد المراجعة', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'تم إرسال طلب التفعيل بنجاح!\n\nيرجى الانتظار ومراسلة المطور عبر الواتساب أو التليجرام لإتمام الدفع وتأكيد تفعيل الحساب.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('مراسلة عبر واتساب (+9647862597668)', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088cc)),
                  onPressed: _openTelegram,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('مراسلة عبر تليجرام (@huzt92)', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ رمز التفعيل غير صحيح!'),
          backgroundColor: Colors.red,
        ),
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
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 48, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تفعيل نظام المبيعات والمخازن',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'يرجى إدخال بياناتك ورمز التفعيل المعتمد',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // الحقول بالترتيب المطلوب بدقة
                  _buildField(_nameController, 'الاسم الكامل', Icons.person),
                  const SizedBox(height: 12),
                  _buildField(_emailController, 'البريد الإلكتروني', Icons.email),
                  const SizedBox(height: 12),
                  _buildField(_usernameController, 'اسم المستخدم', Icons.account_circle),
                  const SizedBox(height: 12),
                  _buildField(_phoneController, 'رقم الهاتف', Icons.phone),
                  const SizedBox(height: 12),
                  _buildField(_codeController, 'رمز التفعيل', Icons.vpn_key, isPassword: true),
                  const SizedBox(height: 16),
                  
                  // أزرار التواصل المباشر تحت الحقول
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _openWhatsApp,
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('واتساب', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _openTelegram,
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('تليجرام', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submitActivation,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إرسال طلب التفعيل والموافقة',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
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
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}
