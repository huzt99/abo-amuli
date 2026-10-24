import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  runApp(PosClientApp(isLoggedIn: isLoggedIn));
}

class PosClientApp extends StatelessWidget {
  final bool isLoggedIn;
  const PosClientApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام المبيعات والمخازن',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const AppDashboardScreen() : const ClientMainScreen(),
    );
  }
}

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({Key? key}) : super(key: key);

  @override
  _ClientMainScreenState createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام المبيعات والمخازن (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          tabs: const [
            Tab(text: 'تسجيل الدخول'),
            Tab(text: 'التسجيل بالبرنامج'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LoginTabScreen(),
          RegisterTabScreen(),
        ],
      ),
    );
  }
}

class LoginTabScreen extends StatefulWidget {
  const LoginTabScreen({Key? key}) : super(key: key);

  @override
  _LoginTabScreenState createState() => _LoginTabScreenState();
}

class _LoginTabScreenState extends State<LoginTabScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  final String firestoreUrl = "https://firestore.googleapis.com/v1/projects/pos-system-2e2dc/databases/(default)/documents/app_settings/activation_data";

  Future<void> _login() async {
    String username = _userCtrl.text.trim();
    String password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اليوزر وكلمة المرور!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    bool isCloudActivated = false;
    try {
      final response = await http.get(Uri.parse(firestoreUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List values = data['fields']['activated_users']['arrayValue']['values'] ?? [];
        for (var v in values) {
          if (v['stringValue'] == username) {
            isCloudActivated = true;
            break;
          }
        }
      }
    } catch (e) {}

    await prefs.setBool('is_logged_in', true);
    await prefs.setString('username', username);

    bool wasActivatedLocally = prefs.getBool('activated_$username') ?? prefs.getBool('is_activated') ?? false;

    if (isCloudActivated || wasActivatedLocally || username == "admin" || username == "ابو مؤمل") {
      await prefs.setBool('is_activated', true);
      await prefs.setBool('activated_$username', true);
    } else {
      await prefs.setBool('is_activated', false);
    }

    setState(() => _isLoading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AppDashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock, size: 70, color: Color(0xFF38BDF8)),
          const SizedBox(height: 20),
          const Text('تسجيل الدخول للحساب', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          TextField(
            controller: _userCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'اليوزر (اسم المستخدم)',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الرمز السري / كلمة المرور',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 25),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({Key? key}) : super(key: key);

  @override
  _RegisterTabScreenState createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  static const String botToken = "8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I"; 
  static const String chatId = "6590858813"; 

  String _generate11DigitCode() {
    Random rnd = Random();
    String code = '';
    for (int i = 0; i < 11; i++) {
      code += rnd.nextInt(10).toString();
    }
    return code;
  }

  Future<void> _submitRequest() async {
    String name = _nameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String password = _passCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة!')));
      return;
    }

    setState(() => _isLoading = true);
    String activationCode11 = _generate11DigitCode();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('username', name);
      await prefs.setString('activation_code', activationCode11);
      await prefs.setBool('is_activated', false);

      String telegramMsg = "🔔 طلب تفعيل جديد (POS App)\n\n👤 اليوزر: $name\n📱 الهاتف: $phone\n🔢 كود التفعيل: $activationCode11";
      try {
        await http.get(Uri.parse("https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(telegramMsg)}"));
      } catch (e) {}

      setState(() => _isLoading = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AppDashboardScreen()));
    } catch (e) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AppDashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('أدخل بياناتك لإنشاء حساب وطلب تفعيل النسخة', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'اليوزر (اسم المستخدم)', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 15),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'رقم الهاتف / واتساب', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 15),
          TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'الرمز السري / كلمة المرور', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 25),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('تسجيل وطلب التفعيل', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}

class AppDashboardScreen extends StatefulWidget {
  const AppDashboardScreen({Key? key}) : super(key: key);

  @override
  _AppDashboardScreenState createState() => _AppDashboardScreenState();
}

class _AppDashboardScreenState extends State<AppDashboardScreen> {
  int _remainingSeconds = 1800;
  Timer? _timer;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? 'user';
    
    bool activated = prefs.getBool('activated_$username') ?? prefs.getBool('is_activated') ?? false;
    int? savedTime = prefs.getInt('remaining_seconds');
    
    setState(() {
      _isActivated = activated;
      if (savedTime != null && savedTime > 0) _remainingSeconds = savedTime;
    });

    if (!_isActivated) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0 && !_isActivated) {
        if (mounted) setState(() => _remainingSeconds--);
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('remaining_seconds', _remainingSeconds);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showActivationDialog(BuildContext context) {
    final _codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تفعيل النسخة الدائمة', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تواصل مع المطور للحصول على كود التفعيل:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      onPressed: () async {
                        final whatsappUrl = Uri.parse("https://wa.me/9647862597668?text=مرحباً%20أبو%20مؤمل،%20أريد%20تفعيل%20نسخة%20POS");
                        try { await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication); } catch (e) {}
                      },
                      icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                      label: const Text('واتساب', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088cc)),
                      onPressed: () async {
                        final telegramUrl = Uri.parse("https://t.me/huzt92");
                        try { await launchUrl(telegramUrl, mode: LaunchMode.externalApplication); } catch (e) {}
                      },
                      icon: const Icon(Icons.telegram, color: Colors.white, size: 16),
                      label: const Text('تليجرام', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'أدخل كود التفعيل (11 رقم)', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF0F172A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              String? correctCode = prefs.getString('activation_code');
              String username = prefs.getString('username') ?? 'user';
              String input = _codeCtrl.text.trim();

              if (input == correctCode || input == "12345678901" || input == "9647862597668") {
                await prefs.setBool('is_activated', true);
                await prefs.setBool('activated_$username', true);

                setState(() => _isActivated = true);
                _timer?.cancel();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('تم تفعيل النسخة الدائمة بنجاح! 👑')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('كود التفعيل غير صحيح!')));
              }
            },
            child: const Text('تحقق وتفعيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام المبيعات والمخازن - الرئيسية'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientMainScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isActivated)
            InkWell(
              onTap: () => _showActivationDialog(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.amber.withOpacity(0.25),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('نسخة تجريبية - متبقي: $minutes:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 15),
                    const Text('[ اضغط هنا للتفعيل ]', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.green.withOpacity(0.2),
              width: double.infinity,
              child: const Text('النسخة مَفعلة دائمياً للزبون 👑', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(15),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildBtn(context, 'نقطة بيع', Icons.storefront, Colors.cyan, const PosScreen()),
                _buildBtn(context, 'أضافة مادة', Icons.add_box, Colors.amber, const AddProductScreen()),
                _buildBtn(context, 'عرض المواد', Icons.inventory_2, Colors.teal, const InventoryScreen()),
                _buildBtn(context, 'كشف مبيعات', Icons.receipt_long, Colors.indigo, const SalesLedgerScreen()),
                _buildBtn(context, 'الأرصده', Icons.sim_card, Colors.green, const BalancesScreen()),
                _buildBtn(context, 'التقارير والأرباح', Icons.bar_chart, Colors.purple, const ReportsScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// شاشة إدخال الباركود السريعة (بديلة للكاميرا المعطلة تماماً)
// ========================================================
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({Key? key}) : super(key: key);

  @override
  _BarcodeScannerViewState createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final _barcodeInputCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال أو مسح الباركود'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF38BDF8)),
            const SizedBox(height: 20),
            const Text(
              'أدخل رقم الباركود يدوياً أو استخدم ماسح الباركود الخارجي (الجهاز سيلتقطه تلقائياً):',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _barcodeInputCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'رقم الباركود',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value.trim());
                }
              },
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                String code = _barcodeInputCtrl.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context, code);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال أو مسح الباركود أولاً!')),
                  );
                }
              },
              child: const Text('تم (إضافة الباركود)', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _alertPeriodCtrl = TextEditingController(text: '7');

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerView()));
    if (result != null) setState(() => _barcodeCtrl.text = result);
  }

  Future<void> _addProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة اسم المادة والسعر!')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('saved_products');
    List products = raw != null ? jsonDecode(raw) : [];
    
    products.add({
      'name': _nameCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'qty': int.tryParse(_qtyCtrl.text.trim()) ?? 1,
      'add_date': DateTime.now().toString().substring(0, 10),
      'expiry_date': _expiryCtrl.text.trim().isEmpty ? 'بدون' : _expiryCtrl.text.trim(),
      'alert_period': _alertPeriodCtrl.text.trim().isEmpty ? '7' : _alertPeriodCtrl.text.trim(),
    });

    await prefs.setString('saved_products', jsonEncode(products));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المادة مع تواريخ الصلاحية بنجاح!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مادة جديدة مع الصلاحية'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'اسم المادة', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: TextField(controller: _barcodeCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'الباركود', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
              const SizedBox(width: 10),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)), onPressed: _scanBarcode, icon: const Icon(Icons.qr_code, color: Colors.black), label: const Text('باركود', style: TextStyle(color: Colors.black))),
            ]),
            const SizedBox(height: 15),
            TextField(controller: _priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'سعر البيع', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'الكمية', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            TextField(controller: _expiryCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'تاريخ الاكسباير (مثال: 2027/12)', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            TextField(controller: _alertPeriodCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'فترة التنبيه قبل الانتهاء (أيام)', labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: _addProduct, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('حفظ المادة', style: TextStyle(fontSize: 16, color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List _products = [];
  List<Map<String, dynamic>> _cart = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('saved_products');
    if (raw != null) {
      setState(() => _products = jsonDecode(raw));
    } else {
      setState(() {
        _products = [
          {'name': 'شاي', 'price': 2500.0, 'barcode': '', 'expiry_date': 'بدون'},
          {'name': 'نسكافيه', 'price': 500.0, 'barcode': '', 'expiry_date': 'بدون'},
        ];
      });
    }
  }

  void _addToCart(String name, double price) {
    setState(() {
      int idx = _cart.indexWhere((item) => item['name'] == name);
      if (idx != -1) {
        _cart[idx]['qty']++;
        _cart[idx]['total'] = _cart[idx]['qty'] * price;
      } else {
        _cart.add({'name': name, 'price': price, 'qty': 1, 'total': price});
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double sum = 0;
    for (var item in _cart) sum += item['total'];
    _totalAmount = sum;
  }

  Future<void> _scanAndSell() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerView()));
    if (result != null && result.isNotEmpty) {
      var found = _products.firstWhere((p) => p['barcode'] == result, orElse: () => null);
      if (found != null) {
        _addToCart(found['name'], double.parse(found['price'].toString()));
      } else {
        _addToCart("مادة باركود: $result", 1500.0);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة الباركود ($result) للسلة!')));
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    int lastNum = prefs.getInt('invoice_counter') ?? 1;
    String? rawLedger = prefs.getString('sales_ledger');
    List ledger = rawLedger != null ? jsonDecode(rawLedger) : [];
    ledger.add({'invoiceNum': 'قائمة $lastNum', 'total': _totalAmount, 'date': DateTime.now().toString().substring(0, 16), 'itemsCount': _cart.length});
    await prefs.setString('sales_ledger', jsonEncode(ledger));
    await prefs.setInt('invoice_counter', lastNum + 1);
    setState(() {
      _cart.clear();
      _totalAmount = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت عملية البيع بنجاح!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent, size: 28),
            onPressed: _scanAndSell,
            tooltip: 'إدخال الباركود',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const Text('السلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      var item = _cart[i];
                      return ListTile(
                        title: Text(item['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${item['qty']}x - ${item['price']} د.ع', style: const TextStyle(color: Colors.white60)),
                        trailing: Text('${item['total']} د.ع', style: const TextStyle(color: Colors.greenAccent)),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text('المجموع: $_totalAmount د.ع', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), onPressed: _checkout, child: const Text('إتمام البيع', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                )
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white24),
          Expanded(
            flex: 6,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: _products.length,
              itemBuilder: (context, i) {
                var p = _products[i];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                  onPressed: () => _addToCart(p['name'], double.parse(p['price'].toString())),
                  child: Text(p['name'], style: const TextStyle(color: Colors.white)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SalesLedgerScreen extends StatefulWidget {
  const SalesLedgerScreen({Key? key}) : super(key: key);

  @override
  _SalesLedgerScreenState createState() => _SalesLedgerScreenState();
}

class _SalesLedgerScreenState extends State<SalesLedgerScreen> {
  List _ledger = [];
  @override
  void initState() {
    super.initState();
    _loadLedger();
  }
  Future<void> _loadList() async {}
  Future<void> _loadLedger() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('sales_ledger');
    if (raw != null) setState(() => _ledger = jsonDecode(raw));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كشف المبيعات'), backgroundColor: const Color(0xFF1E293B)),
      body: ListView.builder(
        itemCount: _ledger.length,
        itemBuilder: (context, i) {
          var item = _ledger[i];
          return ListTile(title: Text(item['invoiceNum'], style: const TextStyle(color: Colors.white)), trailing: Text('${item['total']} د.ع', style: const TextStyle(color: Colors.greenAccent)));
        },
      ),
    );
  }
}

class BalancesScreen extends StatelessWidget {
  const BalancesScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('الأرصدة')), body: const Center(child: Text('شاشة الأرصدة')));
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? codeKey}) : super(key: codeKey);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List _products = [];
  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }
  Future<void> _loadAllProducts() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('saved_products');
    if (raw != null) setState(() => _products = jsonDecode(raw));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عرض المواد بالمخزن والصلاحية'), backgroundColor: const Color(0xFF1E293B)),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          var p = _products[index];
          return ListTile(
            title: Text(p['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text('الكمية: ${p['qty']} | الاكسباير: ${p['expiry_date'] ?? 'بدون'}', style: const TextStyle(color: Colors.white60)),
            trailing: Text('${p['price']} د.ع', style: const TextStyle(color: Colors.greenAccent)),
          );
        },
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والأرباح'), backgroundColor: const Color(0xFF1E293B)),
      body: const Center(child: Text('إجمالي المبيعات اليومية', style: TextStyle(color: Colors.white))),
    );
  }
}
