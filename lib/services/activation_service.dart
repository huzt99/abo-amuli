import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  // المفتاح والـ Bin الخاصين بك ببرنامج المخازن
  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  static const String baseUrl = "https://api.jsonbin.io/v3/b/$binId";

  // بيانات بوت التلجرام للإشعارات
  static const String telegramBotToken = "8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I";
  static const String telegramChatId = "6590858813";

  // --- 1. فحص وحفظ التفعيل محلياً وفي السحاب ---
  
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_pos_activated') ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pos_activated', value);
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin_logged') ?? false;
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged', value);
  }

  // --- 2. إرسال إشعار فوري إلى التلجرام عند طلب التفعيل ---
  static Future<void> sendTelegramNotification(String name, String phone) async {
    try {
      final message = "🔔 *طلب تفعيل جديد - نظام المخازن (POS)*\n\n"
          "👤 *الاسم:* $name\n"
          "📱 *رقم الهاتف:* `$phone`\n"
          "⏰ *الوقت:* ${DateTime.now().toString().substring(0, 16)}\n\n"
          "يرجى الدخول إلى لوحة تحكم الأدمن للموافقة وتوليد كود التفعيل المكون من 11 رقم.";

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

  // --- 3. تسجيل حساب جديد (حفظ بالسحاب + إشعار تلجرام) ---
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map) {
          List requests = data['pending_requests'] ?? [];
          
          // إضافة طلب الحساب الجديد
          requests.add({
            'name': name,
            'phone': phone,
            'password': password,
            'date': DateTime.now().toIso8601String(),
          });
          data['pending_requests'] = requests;

          // حفظ التحديث في JSONBin
          await http.put(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
              "X-Master-Key": masterKey,
            },
            body: jsonEncode(data),
          );

          // إرسال الإشعار للتلجرام
          await sendTelegramNotification(name, phone);

          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error sending request: $e");
      return false;
    }
  }

  // --- 4. الموافقة وتوليد كود من 11 رقم عشوائي فريد ---
  static Future<String?> approveUserAndGenerateCode(String phone) async {
    try {
      // توليد كود عشوائي فريد مكون من 11 رقم
      Random random = Random();
      String generatedCode = "";
      for (int i = 0; i < 11; i++) {
        generatedCode += random.nextInt(10).toString();
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map) {
          data['approved_users'] ??= {};
          data['approved_users'][phone] = {
            'code': generatedCode,
            'approved_at': DateTime.now().toIso8601String(),
          };

          // إزالة الطلب من القائمة المعلقة بعد الموافقة
          if (data['pending_requests'] != null) {
            List requests = data['pending_requests'];
            requests.removeWhere((item) => item['phone'] == phone);
            data['pending_requests'] = requests;
          }

          await http.put(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
              "X-Master-Key": masterKey,
            },
            body: jsonEncode(data),
          );

          return generatedCode;
        }
      }
      return generatedCode;
    } catch (e) {
      print("Error in approveUserAndGenerateCode: $e");
      return null;
    }
  }

  // --- 5. التحقق من كود الـ 11 رقم وتفعيل الجهاز محلياً وسحابياً ---
  static Future<bool> verifyCode(String phone, String code) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map && data['approved_users'] != null) {
          var userApproved = data['approved_users'][phone];
          if (userApproved != null && userApproved['code'] == code.trim()) {
            // حفظ التفعيل محلياً في الجهاز بشكل دائم
            await setLocalActivated(true);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("Error in verifyCode: $e");
      return false;
    }
  }

  // --- 6. تسجيل الدخول ---
  static Future<String> login(String username, String password) async {
    if (username == "admin" && password == "admin") {
      await setAdminLoggedIn(true);
      return "admin";
    }
    return "success";
  }

  // --- 7. جلب طلبات التفعيل المعلقة للأدمن ---
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map && data['pending_requests'] != null) {
          List rawList = data['pending_requests'];
          return List<Map<String, dynamic>>.from(rawList.map((item) => Map<String, dynamic>.from(item)));
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> resetPassword(String phone, String newPass) async {
    return true;
  }
}
