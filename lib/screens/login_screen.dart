import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activation_service.dart';
import 'dashboard_screen.dart';
import 'admin_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;

  // فتح رابط الواتساب للتواصل
  Future<void> _openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/9647862597668?text=${Uri.encodeComponent('السلام عليكم، قمت بإرسال طلب تفعيل للبرنامج باسم: ${_usernameController.text}')}');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الواتساب، يرجى المراسلة على 07862597668')),
      );
    }
  }

  // عملية معالجة التفعيل/تسجيل الدخول
  void _handleActivation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String code = _codeController.text.trim();
    String name = _fullNameController.text.trim();
    String phone = _phoneController.text.trim();

    // 1. الدخول الخاص بك كأدمن ماستر (أبو مؤمل)
    if (username == ActivationService.adminUsername && code == ActivationService.adminPassword) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
      );
      return;
    }

    // 2. طلب تفعيل الزبائن برمز التفعيل الموحد
    if (code == '20319920') {
      // إرسال الإشعار للتلكرام
      bool sent = await ActivationService.sendTelegramActivationRequest(
        fullName: name,
        email: email,
        username: username,
        phone: phone,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // إظهار تنبيه للزبون وعدم السماح له بالدخول نهائياً حتى توافق عليه
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('⏳ الطلب قيد الانتظار', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: Text(
            sent
                ? 'تم إرسال طلب التفعيل إلى المطور بنجاح.\n\nحسابك حالياً قيد التنشيط، يرجى التواصل عبر الواتساب لإكمال تفعيل الحساب والدخول.'
                : 'تم تسجيل الطلب، يرجى التواصل مباشرة مع المطور لتفعيل حسابك.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () {
                Navigator.pop(context);
                _openWhatsApp();
              },
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('مراسلة المطور على واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ رمز التفعيل غير صحيح، يرجى التواصل مع الدعم (+9647862597668)'),
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
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.point_of_sale_sharp, size: 60, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 12),
                  const Text(
                    'نظام إدارة المبيعات والمخازن',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'تفعيل البرنامج والدخول',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_fullNameController, 'الاسم الكامل', Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email, isEmail: true),
                  const SizedBox(height: 12),
                  _buildTextField(_usernameController, 'اسم المستخدم', Icons.account_circle),
                  const SizedBox(height: 12),
                  _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone, isPhone: true),
                  const SizedBox(height: 12),
                  _buildTextField(_codeController, 'رمز التفعيل', Icons.vpn_key, isPassword: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleActivation,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إرسال طلب التفعيل',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.support_agent, color: Color(0xFF4ADE80)),
                    label: const Text(
                      'الدعم الفني عبر واتساب',
                      style: TextStyle(color: Color(0xFF4ADE80)),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isPhone = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
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
