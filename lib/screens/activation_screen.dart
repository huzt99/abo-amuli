import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/activation_service.dart';
import 'admin_approval_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final TextEditingController _regUserControl = TextEditingController();
  final TextEditingController _regPassControl = TextEditingController();
  final TextEditingController _regCodeControl = TextEditingController();

  final TextEditingController _loginUserControl = TextEditingController();
  final TextEditingController _loginPassControl = TextEditingController();

  bool _isStepTwoCode = false; // التحكم بإظهار التفعيل بعد إدخال البيانات الضغط على "تسجيل"
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkSavedActivation();
  }

  Future<void> _checkSavedActivation() async {
    bool isActivated = await ActivationService.isLocalActivated();
    if (isActivated && mounted) {
      _navigateToMainDashboard();
    }
  }

  void _navigateToMainDashboard() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(title: const Text('نظام المبيعات والمخازن - النسخة المفعلة'), backgroundColor: const Color(0xFF1E293B)),
          body: const Center(
            child: Text('🎉 مرحباً بك! التطبيق مفعل وجاهز للعمل.', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/9647862597668?text=${Uri.encodeComponent('السلام عليكم، قمت بتسجيل حساب باسم: ${_regUserControl.text} وأريد كود التفعيل.')}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://t.me/huzt92');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // الخطوة 1: عند الضغط على زر "تسجيل الحساب"
  void _onRegisterSubmit() {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _isStepTwoCode = true; // الانقال فوراً لشاشة إدخال كود التفعيل وحساباتك
    });
  }

  // الخطوة 2: عند الضغط على زر "تفعيل الحساب"
  void _onActivationSubmit() async {
    String username = _regUserControl.text.trim();
    String code = _regCodeControl.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود التفعيل'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (code == '20319920') {
      setState(() => _isLoading = true);
      String email = username.contains('@') ? username : '$username@client.com';

      // حفظ الطلب بالسحابة والذاكرة المحلية
      await ActivationService.registerUserDual(username: username, email: email);

      // إرسال إشعار التليجرام الفوري لك
      await ActivationService.sendTelegramActivationRequest(username: username, email: email);

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
            'رجاءً انتظر موافقة المطور!\n\nتم إرسال طلب تفعيل حسابك بنجاح، وسيتم مراجعته وتفعيله فوراً ليمكنك تسجيل الدخول.',
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

  // تسجيل الدخول (للأدمن وللمستخدمين)
  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    String userInput = _loginUserControl.text.trim();
    String passInput = _loginPassControl.text.trim();

    // دخول الأدمن الماستر الخاص بك
    if (userInput == 'huzt.m1@gmail.com' && passInput == '20819921992') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminApprovalScreen()),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool isActivated = await ActivationService.checkUserActivationDual(userInput);

    setState(() => _isLoading = false);

    if (isActivated) {
      _navigateToMainDashboard();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الحساب غير مفعل بعد أو بانتظار موافقة المطور!'),
          backgroundColor: Colors.orange,
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 50, color: Color(0xFF38BDF8)),
                const SizedBox(height: 12),
                
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF38BDF8),
                  labelColor: const Color(0xFF38BDF8),
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'إنشاء حساب جديد'),
                    Tab(text: 'تسجيل الدخول'),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 360,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // --- تبويب إنشاء حساب جديد ---
                      Form(
                        key: _registerFormKey,
                        child: Column(
                          children: [
                            // الخطوة 1: أدخل البيانات فقط
                            if (!_isStepTwoCode) ...[
                              _buildField(_regUserControl, 'اسم المستخدم أو البريد', Icons.person),
                              const SizedBox(height: 12),
                              _buildField(_regPassControl, 'كلمة المرور', Icons.lock, isPassword: true),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                                  onPressed: _onRegisterSubmit,
                                  child: const Text('تسجيل الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],

                            // الخطوة 2: تظهر نافذة التفعيل وأزرار التواصل فقط بعد الضغط على تسجيل الحساب
                            if (_isStepTwoCode) ...[
                              _buildField(_regCodeControl, 'أدخل كود التفعيل', Icons.vpn_key, isPassword: true),
                              const SizedBox(height: 14),
                              const Text('للحصول على كود التفعيل، يرجى التواصل مع المطور:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                                      onPressed: _openWhatsApp,
                                      icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                                      label: const Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088cc)),
                                      onPressed: _openTelegram,
                                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                                      label: const Text('تليجرام', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                  onPressed: _isLoading ? null : _onActivationSubmit,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('تفعيل الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() => _isStepTwoCode = false),
                                child: const Text('رجوع لتعديل البيانات', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // --- تبويب تسجيل الدخول ---
                      Form(
                        key: _loginFormKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildField(_loginUserControl, 'البريد أو اسم المستخدم', Icons.account_circle),
                            const SizedBox(height: 14),
                            _buildField(_loginPassControl, 'كلمة المرور', Icons.lock, isPassword: true),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      style: const TextStyle(color: Colors.white, fontSize: 13),
      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
