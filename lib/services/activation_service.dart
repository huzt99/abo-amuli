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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  Future<void> _openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/9647862597668?text=${Uri.encodeComponent('السلام عليكم، قمت بإرسال طلب تفعيل للبرنامج باسم: ${_usernameController.text}')}');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _submitActivation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String username = _usernameController.text.trim();
    String code = _codeController.text.trim();
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();

    // 1. دخول الأدمن الماستر الخاص بك
    if (username == ActivationService.adminUsername && code == ActivationService.adminPassword) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
      );
      return;
    }

    // 2. كود التفعيل الموحد للزبائن (يرسل طلب لتليجرام ويقفل الحساب)
    if (code == '20319920') {
      bool sent = await ActivationService.sendTelegramActivationRequest(
        fullName: name,
        email: email,
        username: username,
        phone: phone,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // إظهار نافذة قفل الانتظار وعدم السماح بالدخول نهائياً
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
          content: Text(
            sent
                ? 'تم إرسال طلب التفعيل إلى المطور بنجاح!\n\nحسابك مغلق حالياً لحين موافقة المطور. يرجى مراسلته عبر الواتساب لإتمام الدفع وتفعيل البرنامج.'
                : 'حدث خطأ في الاتصال، يرجى مراسلة المطور مباشرة.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () {
                Navigator.pop(context);
                _openWhatsApp();
              },
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('مراسلة المطور واتساب', style: TextStyle(color: Colors.white)),
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
                  _buildField(_nameController, 'الاسم الكامل', Icons.person),
                  const SizedBox(height: 12),
                  _buildField(_emailController, 'البريد الإلكتروني', Icons.email),
                  const SizedBox(height: 12),
                  _buildField(_usernameController, 'اسم المستخدم', Icons.account_circle),
                  const SizedBox(height: 12),
                  _buildField(_phoneController, 'رقم الهاتف', Icons.phone),
                  const SizedBox(height: 12),
                  _buildField(_codeController, 'رمز التفعيل', Icons.vpn_key, isPassword: true),
                  const SizedBox(height: 24),
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
