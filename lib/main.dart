import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      home: const ClientHomeScreen(),
    );
  }
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  static const String botToken = "7736630424:AAHE4Jj70yqH-d5h0x7Jg6a9xY0xY0xY0xY"; // تليجرام بوتك
  static const String chatId = "5304240000"; // أيدي أو معرف قناتك أو حسابك

  bool _isTrialActive = true;
  int _remainingSeconds = 180; // 3 دقائق تجريبية
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTrialTimer();
  }

  void _startTrialTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTrialActive = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // إرسال طلب التفعيل للسحاب ولتليجرام
  Future<void> _submitActivationRequest() async {
    String name = _nameCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String password = _passCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة!')),
      );
      return;
    }

    try {
      // 1. جلب البيانات الحالية من سحاب JSONBin
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

      // إضافة الطلب الجديد للقائمة
      pendingList.add({
        'name': name,
        'phone': phone,
        'password': password,
        'date': DateTime.now().toIso8601String(),
      });

      data['pending_requests'] = pendingList;

      // 2. تحديث السحاب بالطلب الجديد
      await http.put(
        Uri.parse("https://api.jsonbin.io/v3/b/$binId"),
        headers: {
          "Content-Type": "application/json",
          "X-Master-Key": masterKey,
        },
        body: jsonEncode(data),
      );

      // 3. إرسال إشعار تليجرام فوري لك
      String telegramMsg = "🔔 طلب تسجيل وتفعيل جديد - نظام المخازن (POS)\n\n👤 اليوزر: $name\n📱 الهاتف: $phone\n🔑 الرمز: $password\n⏰ الوقت: ${DateTime.now()}";
      // استدعاء بوت تليجرام إن أمكن
      try {
        await http.get(Uri.parse("https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(telegramMsg)}"));
      } catch (_) {}

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('تم إرسال الطلب بنجاح', style: TextStyle(color: Colors.white)),
          content: Text(
            'تم إرسال طلبك إلى المطور للتفعيل.\nيمكنك الاستمرار بالتجربة لمدة (${_remainingSeconds ~/ 60} دقائق).\nبانتظار موافقة الأدمن لتفعيل حسابك بشكل دائم.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً', style: TextStyle(color: Color(0xFF38BDF8))),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في الاتصال بالسحاب!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام المبيعات والمخازن (POS)'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط العداد التجريبي العلوي
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isTrialActive ? Colors.amber.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isTrialActive ? Colors.amber : Colors.red),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: _isTrialActive ? Colors.amber : Colors.red),
                  const SizedBox(width: 10),
                  Text(
                    _isTrialActive
                        .toString()
                        .contains('true') // للتوضيح
                        ? 'نسخة تجريبية مؤقتة - متبقي: $minutes:${seconds.toString().padLeft(2, '0')}'
                        : 'انتهت الفترة التجريبية - بانتظار تفعيل الأدمن',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أدخل بياناتك لإنشاء حساب والبدء المؤقت بالبرنامج',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
              onPressed: _submitActivationRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تسجيل وطلب تفعيل الحساب', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
