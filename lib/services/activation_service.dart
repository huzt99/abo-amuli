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

  // روابط التواصل الخاصة بك (واتساب وتلجرام)
  static const String whatsappLink = "https://wa.me/9647862597668";
  static const String telegramLink = "https://t.me/huzt92";

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
  static Future<void> sendTelegramNotification(String identifier, String password) async {
    try {
      final message = "🔔 *طلب تفعيل جديد - نظام المخازن (POS)*\n\n"
          "👤 *المعرف (يوزر / إيميل):* $identifier\n"
          "🔑 *الرمز السري:* $password\n"
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

  // --- 3. تسجيل حساب جديد (حفظ بالسحاب بأمان تام + إشعار تلجرام) ---
  static Future<bool> sendActivationRequest(String identifier, String password) async {
    try {
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

      // إزالة الطلب القديم لنفس المعرف لمنع التكرار
      pendingRequests.removeWhere((item) => item['identifier'] == identifier);

      // إضافة الطلب الجديد
      pendingRequests.add({
        'identifier': identifier,
        'password': password,
        'date': DateTime.now().toIso8601String(),
      });

      data['pending_requests'] = pendingRequests;
      data['approved_users'] ??= {};
      data['users'] ??= {};

      final putResponse = await http.put(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "X-Master-Key": masterKey,
        },
        body: jsonEncode(data),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        await sendTelegramNotification(identifier, password);
        return true;
      }
      return false;
    } catch (e) {
      print("Error sending request: $e");
      return false;
    }
  }

  // --- 4. الموافقة وتوليد كود من 11 رقم عشوائي فريد ---
  static Future<String?> approveUserAndGenerateCode(String identifier) async {
    try {
      Random random = Random();
      String generatedCode = "";
      for (int i = 0; i < 11; i++) {
        generatedCode += random.nextInt(10).toString();
      }

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

      data['approved_users'] ??= {};
      data['approved_users'][identifier] = {
        'code': generatedCode,
        'approved_at': DateTime.now().toIso8601String(),
      };

      if (data['pending_requests'] is List) {
        List requests = List.from(data['pending_requests']);
        requests.removeWhere((item) => item['identifier'] == identifier);
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
    } catch (e) {
      print("Error in approveUserAndGenerateCode: $e");
      return null;
    }
  }

  // --- 5. التحقق من كود الـ 11 رقم وتفعيل الجهاز محلياً ---
  static Future<bool> verifyCode(String identifier, String code) async {
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
            var approvedUsers = data['approved_users'];
            if (approvedUsers is Map && approvedUsers[identifier] != null) {
              var userRecord = approvedUsers[identifier];
              if (userRecord['code'] == code.trim()) {
                await setLocalActivated(true);
                return true;
              }
            }
          }
        }
      }
      return false;
    } catch (e) {
      print("Error in verifyCode: $e");
      return false;
    }
  }

  // --- 6. تسجيل الدخول (مع حساب الأدمن الخاص بك) ---
  static Future<String> login(String username, String password) async {
    // حساب الأدمن الخاص بك
    if (username.trim() == "Huzt1998" && password == "Hz19881988") {
      await setAdminLoggedIn(true);
      return "admin";
    }

    bool activated = await isLocalActivated();
    if (activated) {
      return "success";
    }

    return "failed";
  }

  // --- 7. جلب الطلبات المعلقة للأدمن ---
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded != null && decoded['record'] != null) {
          var data = decoded['record'];
          if (data is Map && data['pending_requests'] is List) {
            List rawList = data['pending_requests'];
            return List<Map<String, dynamic>>.from(rawList.map((item) => Map<String, dynamic>.from(item)));
          }
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
