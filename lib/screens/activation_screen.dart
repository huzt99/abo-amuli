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

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _loginIdentifierController = TextEditingController();
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) _showMsg('تعذر فتح الرابط');
    }
  }

  // 1️⃣ إرسال الطلب للتليجرام والسحاب
  void _handleSendRequest() async {
    setState(() => _isLoading = true);
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showMsg('يرجى كتابة الاسم ورقم الهاتف');
      setState(() => _isLoading = false);
      return;
    }

    bool sent = await ActivationService.sendActivationRequest(name, phone);
    setState(() => _isLoading = false);

    if (sent) {
      _showMsg('تم إرسال طلب التفعيل بنجاح! سيتم تنبيه المطور والتفعيل قريباً');
      _nameController.clear();
      _phoneController.clear();
    } else {
      _showMsg('فشل إرسال الطلب، تأكد من الاتصال بالإنترنت');
    }
  }

  // 2️⃣ تسجيل الدخول أو فحص التفعيل
  void _handleLogin() async {
    setState(() => _isLoading = true);
    String id = _loginIdentifierController.text.trim();
    String pass = _loginPasswordController.text.trim();

    if (id.isEmpty) {
      _showMsg('يرجى إدخال رقم الهاتف أو بريد الأدمن');
      setState(() => _isLoading = false);
      return;
    }

    String result = await ActivationService.loginOrCheckApproval(id, pass);
    setState(() => _isLoading = false);

    if (result == 'ADMIN') {
      _showMsg('تم تسجيل الدخول كـ مشرف عام');
      _navigateToMainDashboard();
    } else if (result == 'APPROVED') {
      _showMsg('حسابك مفعل! أهلاً بك في النظام');
      _navigateToMainDashboard();
    } else {
      _showMsg('الحساب لم يتم تفعيله بعد من قبل الأدمن');
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
        title: const Text('نظام المبيعات - طلب تفعيل', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'إرسال طلب تفعيل'),
            Tab(text: 'تسجيل الدخول / الفحص'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('أدخل بياناتك وسيصل إشعار فوري للمطور لتفعيل حسابك', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('الاسم الكامل / اسم المحل', Icons.store),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رقم الهاتف / واتساب', Icons.phone),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleSendRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال طلب التفعيل', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                const Text('للتواصل المباشر مع المطور:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                        onPressed: () => _launchURL('https://t.me/huzt_m'),
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('تليجرام', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('للحسابات المفعلة أو دخول المشرف العام', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _loginIdentifierController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رقم الهاتف (للعميل) أو البريد (للأدمن)', Icons.person),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('كلمة المرور (خاصة بالأدمن فقط)', Icons.lock),
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
