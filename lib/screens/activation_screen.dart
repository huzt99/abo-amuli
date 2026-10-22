import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activation_service.dart';
import 'main_dashboard_screen.dart';
import 'admin_panel_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // حقول إرسال طلب التفعيل
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(); // خانة الرمز للحساب
  final _activationCodeController = TextEditingController();

  // حقول تسجيل الدخول
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkInitialStatus();
  }

  void _checkInitialStatus() async {
    bool isAdmin = await ActivationService.isAdminLoggedIn();
    if (isAdmin && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
      return;
    }

    bool isActivated = await ActivationService.isLocalActivated();
    if (isActivated && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()));
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) _showMsg('تعذر فتح الرابط');
    }
  }

  // إرسال الطلب مع كلمة المرور
  void _handleSendRequest() async {
    setState(() => _isLoading = true);
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showMsg('يرجى ملء كافة الحقول المتاحة (الاسم، الهاتف، وكلمة المرور)');
      setState(() => _isLoading = false);
      return;
    }

    bool sent = await ActivationService.sendActivationRequest(name, phone, password);
    setState(() => _isLoading = false);

    if (sent) {
      setState(() => _showCodeInput = true);
      _showMsg('تم إرسال الطلب للمطور! أدخل كود التفعيل (11 رقم) عند استلامه');
    } else {
      _showMsg('فشل إرسال الطلب، تأكد من الاتصال بالإنترنت');
    }
  }

  void _handleVerifyCode() async {
    setState(() => _isLoading = true);
    String phone = _phoneController.text.trim();
    String code = _activationCodeController.text.trim();

    if (code.length != 11) {
      _showMsg('كود التفعيل يجب أن يتكون من 11 رقم بالضبط');
      setState(() => _isLoading = false);
      return;
    }

    bool success = await ActivationService.verifyCode(phone, code);
    setState(() => _isLoading = false);

    if (success) {
      _showMsg('تم التفعيل بنجاح! أهلاً بك');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()));
    } else {
      _showMsg('كود التفعيل غير صحيح أو لم تتم الموافقة عليه بعد');
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    String username = _loginUsernameController.text.trim();
    String password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMsg('يرجى ملء اسم المستخدم وكلمة المرور');
      setState(() => _isLoading = false);
      return;
    }

    String result = await ActivationService.login(username, password);
    setState(() => _isLoading = false);

    if (result == 'ADMIN') {
      _showMsg('أهلاً بك يا مشرف النظام');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
    } else if (result == 'APPROVED') {
      _showMsg('تم تسجيل الدخول بنجاح');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()));
    } else {
      _showMsg('بيانات الدخول غير صحيحة أو الحساب غير مفعل');
    }
  }

  // نافذة "نسيت كلمة المرور"
  void _showForgotPasswordDialog() {
    final phoneCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إعادة تعيين كلمة المرور', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('رقم الهاتف المسجل', Icons.phone),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('الرمز السري الجديد', Icons.lock_reset),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              String phone = phoneCtrl.text.trim();
              String newPass = newPassCtrl.text.trim();
              if (phone.isEmpty || newPass.isEmpty) {
                _showMsg('يرجى إدخال الهاتف والرمز الجديد');
                return;
              }
              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool ok = await ActivationService.resetPassword(phone, newPass);
              setState(() => _isLoading = false);
              if (ok) {
                _showMsg('تم تغيير كلمة المرور بنجاح، يمكنك تسجيل الدخول الآن');
              } else {
                _showMsg('لم يتم العثور على حساب مرتبط برقم الهاتف هذا');
              }
            },
            child: const Text('حفظ الرمز الجديد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        title: const Text('نظام المبيعات والمخازن', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'إرسال طلب تفعيل'),
            Tab(text: 'تسجيل الدخول'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1️⃣ إرسال طلب التفعيل
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('أدخل بياناتك ورمز حسابك للحصول على كود التفعيل', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رمز الحساب / كلمة المرور', Icons.lock),
                ),
                const SizedBox(height: 20),
                if (!_showCodeInput)
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

                if (_showCodeInput) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _activationCodeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('أدخل كود التفعيل المكون من 11 رقم', Icons.vpn_key),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _handleVerifyCode,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تفعيل وتأكيد الكود', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        onPressed: () => _launchURL('https://wa.me/9647800000000'),
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

          // 2️⃣ تسجيل الدخول مع نسيان كلمة المرور
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تسجيل الدخول بالحساب المفعل', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: _loginUsernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('رقم الهاتف / الاسم', Icons.person),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('الرمز السري / كلمة المرور', Icons.lock),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
