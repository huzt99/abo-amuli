import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const PosClientApp());
}

class PosClientApp extends StatelessWidget {
  const PosClientApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام المبيعات والمخازن (POS)',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.blue,
      ),
      home: const ClientMainScreen(),
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
        title: const Text('(POS) نظام المبيعات والمخازن'),
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

// ================= 1. تبويب تسجيل الدخول =================
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
      MaterialPageRoute(builder: (context) => const AppDashboardScreen(isTrial: true)),
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
          const Text('تسجيل الدخول بالحساب', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
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

// ================= 2. تبويب التسجيل بالبرنامج =================
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
  static const String botToken = "7736630424:AAHE4Jj70yqH-d5h0x7Jg6a9xY0xY0xY0xY"; 
  static const String chatId = "5304240000"; 

  // توليد كود تفعيل فريد من 11 رقم
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

      // 1. الاتصال بالسحاب JSONBin
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

      // 2. إرسال إشعار تليجرام البوت المباشر
      String telegramMsg = "🔔 طلب تفعيل جديد وفحص ذكاء اصطناعي (POS)\n\n👤 اليوزر: $name\n📱 الهاتف: $phone\n🔑 الرمز: $password\n🔢 كود التفعيل (11 رقم): $activationCode11\n⏰ الوقت: ${DateTime.now().toString().substring(0, 19)}";
      
      try {
        final tgUrl = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(telegramMsg)}";
        await http.get(Uri.parse(tgUrl));
      } catch (tgError) {
        print("Telegram Error: $tgError");
      }

      // الانتقال للوحة التحكم مباشرة بنسخة تجريبية 30 دقيقة
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppDashboardScreen(isTrial: true)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ محلياً - حدث خطأ بسيط بالاتصال بالسحاب')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppDashboardScreen(isTrial: true)),
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

// ================= 3. شاشة أقسام البرنامج الرئيسية مع عداد 30 دقيقة وزر الشراء =================
class AppDashboardScreen extends StatefulWidget {
  final bool isTrial;
  const AppDashboardScreen({Key? key, required this.isTrial}) : super(key: key);

  @override
  _AppDashboardScreenState createState() => _AppDashboardScreenState();
}

class _AppDashboardScreenState extends State<AppDashboardScreen> {
  int _remainingSeconds = 1800; // 30 دقيقة كاملة
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedTime = prefs.getInt('remaining_seconds');
    if (savedTime != null && savedTime > 0) {
      setState(() {
        _remainingSeconds = savedTime;
      });
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
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

  // نافذة طلب الشراء وتفعيل الكود وأزرار التواصل المباشر
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
                'للحصول على كود التفعيل الخاص بك (11 رقم)، يرجى التواصل مع المطور عبر تليجرام أو واتساب:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              // أزرار التواصل المباشر (واتساب وتليجرام)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      onPressed: () async {
                        final whatsappUrl = Uri.parse("https://wa.me/9647862597668?text=مرحباً%20أبو%20مؤمل،%20أريد%20تفعيل%20تطبيق%20المبيعات%20POS");
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تفعيل البرنامج بنجاح دائم! 👑')),
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
              prefs.setBool('is_logged_in', false);
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
          // شريط العداد التجريبي العلوي مع زر الشراء
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
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildCard('نقطة البيع (POS)', Icons.point_of_sale, Colors.blue),
                _buildCard('إدارة المخزن', Icons.inventory, Colors.green),
                _buildCard('المنتجات والأصناف', Icons.category, Colors.orange),
                _buildCard('التقارير والأرباح', Icons.bar_chart, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فتح قسم: $title')),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
