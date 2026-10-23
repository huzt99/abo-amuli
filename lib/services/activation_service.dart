import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  // المفتاح والـ Bin الخاصين بك ببرنامج المخازن
  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  static const String baseUrl = "https://api.jsonbin.io/v3/b/$binId";

  // بيانات بوت التلجرام للإشعارات الفورية لك
  static const String telegramBotToken = "8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I";
  static const String telegramChatId = "6590858813";

  // روابط التواصل الخاصة بك
  static const String whatsappLink = "https://wa.me/9647862597668";
  static const String telegramLink = "https://t.me/huzt92";

  // --- 1. إدارة التفعيل المحلي والمؤقت (3 دقائق) ---
  
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_pos_activated') ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pos_activated', value);
  }

  // بدء العد التنازلي للتجربة المؤقتة (3 دقائق) عند التسجيل لأول مرة
  static Future<void> startTempActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temp_activation_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isTempActivationValid() async {
    final prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('temp_activation_time');
    if (startTime == null) return false;

    int diff = DateTime.now().millisecondsSinceEpoch - startTime;
    return diff <= (3 * 60 * 1000); // 3 دقائق بالضبط
  }

  // --- 2. إرسال إشعار فوري إلى بوت التلجرام عند تسجيل مستخدم جديد ---
  static Future<void> sendTelegramNotification(String name, String phone, String password) async {
    try {
      final message = "🔔 *طلب تسجيل وتفعيل جديد - نظام المخازن (POS)*\n\n"
          "👤 *اليوزر / الإيميل:* `$name`\n"
          "📱 *رقم الهاتف:* `$phone`\n"
          "🔑 *الرمز السري:* `$password`\n"
          "⏰ *الوقت:* ${DateTime.now().toString().substring(0, 16)}\n\n"
          "يرجى الموافقة على الحساب ليتمكن المستخدم من الدخول نهائياً.";

      final url = "https://api.telegram.org/bot$telegramBotToken/sendMessage";
      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chat_id": telegramChatId,
          "text": message,
          "parse_mode": "Markdown",
        }),
      );
    } catch (e) {
      print("Telegram Error: $e");
    }
  }

  // --- 3. التسجيل بالبرنامج (بدء المؤقت 3 دقائق + إرسال بالسحاب والتلجرام) ---
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    try {
      await startTempActivation(); // بدء التجربة المؤقتة 3 دقائق فوراً
      await sendTelegramNotification(name, phone, password); // إرسال الإشعار للتلجرام

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      Map<String, dynamic> data = {};
      if (response.statusCode == 200) {
        try {
          var decoded = jsonDecode(response.body);
          if (decoded != null && decoded['record'] != null) {
            data = Map<String, dynamic>.from(decoded['record']);
          }
        } catch (_) {}
      }

      List pendingRequests = [];
      if (data['pending_requests'] is List) {
        pendingRequests = List.from(data['pending_requests']);
      }

      // منع التكرار وإزالة الطلب القديم إن وجد
      pendingRequests.removeWhere((item) => item['phone'] == phone || item['name'] == name);

      pendingRequests.add({
        'name': name,
        'phone': phone,
        'password': password,
        'date': DateTime.now().toIso8601String(),
      });

      data['pending_requests'] = pendingRequests;
      data['approved_users'] ??= {};

      await http.put(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "X-Master-Key": masterKey,
        },
        body: jsonEncode(data),
      );

      return true;
    } catch (e) {
      print("Register Error: $e");
      return true; // ضمان فتح البرنامج مؤقتم للمستخدم حتى لو حدثت مشكلة بالشبكة
    }
  }

  // --- 4. فحص حالة الاعتماد السحابي (عند تسجيل الدخول) ---
  static Future<bool> checkApprovalStatus(String identifier) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded != null && decoded['record'] != null) {
          var data = decoded['record'];
          if (data is Map && data['approved_users'] != null) {
            var approved = data['approved_users'];
            if (approved is Map) {
              for (var key in approved.keys) {
                if (key.toString().trim() == identifier.trim()) {
                  await setLocalActivated(true); // حفظ التفعيل الدائم محلياً
                  return true;
                }
              }
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- 5. تسجيل الدخول ---
  static Future<String> login(String username, String password) async {
    // التحقق من الاعتماد السحابي أو التفعيل المحلي
    bool isApproved = await checkApprovalStatus(username.trim());
    if (isApproved || await isLocalActivated()) {
      return "success";
    }

    return "failed";
  }

  // دوال إضافية للتوافق مع الواجهات القديمة إن نُوديت
  static Future<bool> verifyCode(String phone, String code) async {
    return await checkApprovalStatus(phone);
  }

  static Future<bool> resetPassword(String phone, String newPass) async {
    return true;
  }
}
