import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activation_service.dart';
import 'main_dashboard_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // حقول التسجيل (عميل جديد)
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  // حقول تسجيل الدخول
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkInitialStatus();
  }

  void _checkInitialStatus() async {
    bool isActivated = await ActivationService.isLocalActivated();
    bool isAdmin = await ActivationService.isAdminLoggedIn();
    if ((isActivated || isAdmin) && mounted) {
      _navigateToMainDashboard();
    }
  }

  void _navigateToMainDashboard() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
    );
  }

  // التواصل مع المطور عبر واتساب أو تليجرام
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    }
  }

  // تنفيذ طلب التفعيل
  void _handleActivation() async {
    setState(() => _isLoading = true);
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String code = _codeController.text.trim();

    if (name.isEmpty || phone.isEmpty || code.isEmpty) {
      _showMsg('يرجى ملء جميع الحقول');
      setState(() => _isLoading = false);
      return;
    }

    bool success = await ActivationService.registerAndActivate(name, phone, code);
    setState(() => _isLoading = false);

    if (success) {
      _showMsg('تم التفعيل بنجاح! أهلاً بك');
      _navigateToMainDashboard();
    } else {
      _showMsg('رمز التفعيل غير صحيح (الرمز الصحيح: 20319920)');
    }
  }

  // تنفيذ تسجيل الدخول
  void _handleLogin() async {
    setState(() => _isLoading = true);
    String email = _loginEmailController.text.trim();
    String password = _loginPasswordController.text.trim();

    bool success = await ActivationService.login(email, password);
    setState(() => _isLoading = false);

    if (success) {
      _showMsg('تم تسجيل الدخول بنجاح');
      _navigateToMainDashboard();
    } else {
      _showMsg('بيانات الدخول غير صحيحة أو الحساب غير مفعل');
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('تفعيل النظام وتسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'طلب تفعيل جديد'),
            Tab(text: 'تسجيل الدخول'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب التفعيل الجديد
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('أدخل معلوماتك للحصول على التفعيل الفوري', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('الاسم الكامل', Icons.person),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رقم الهواتف / واتساب', Icons.phone),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رمز التفعيل', Icons.vpn_key),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleActivation,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تفعيل النظام', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                const Text('للحصول على رمز التفعيل، تواصل مع المطور مباشرة:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        onPressed: () => _launchURL('https://wa.me/9647800000000'), // ضع رقمك هنا
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text('واتساب', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC)),
                        onPressed: () => _launchURL('https://t.me/huzt_m'), // ضع معرفك هنا
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('تليجرام', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // تبويب تسجيل الدخول
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تسجيل الدخول للحسابات المفعلة أو حساب المشرف العام', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _loginEmailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('البريد الإلكتروني / اسم المستخدم', Icons.email),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('كلمة المرور', Icons.lock),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('دخول للنظام', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
    );
  }
}
