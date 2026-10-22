import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  static const String baseUrl = "https://api.jsonbin.io/v3/b/$binId";

  static const String telegramBotToken = "8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I";
  static const String telegramChatId = "6590858813";

  static const String whatsappLink = "https://wa.me/9647862597668";
  static const String telegramLink = "https://t.me/huzt92";

  // --- 1. إدارة التفعيل المحلي والمؤقت ---
  
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_pos_activated') ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pos_activated', value);
  }

  // حفظ وقت بدء التماثل المؤقت (3 دقائق)
  static Future<void> startTempActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temp_activation_time', DateTime.now().millisecondsSinceEpoch);
  }

  // فحص هل ما زال التفعيل المؤقت شاملاً (خلال 3 دقائق)
  static Future<bool> isTempActivationValid() async {
    final prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('temp_activation_time');
    if (startTime == null) return false;

    int diff = DateTime.now().millisecondsSinceEpoch - startTime;
    return diff <= (3 * 60 * 1000); // 3 دقائق
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin_logged') ?? false;
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged', value);
  }

  // --- 2. إرسال إشعار التلجرام ---
  static Future<void> sendTelegramNotification(String username, String phone, String password) async {
    try {
      final message = "🔔 *طلب تسجيل وتفعيل جديد - نظام المخازن (POS)*\n\n"
          "👤 *اليوزر / الإيميل:* `$username`\n"
          "📱 *رقم الهاتف:* `$phone`\n"
          "🔑 *الرمز السري:* `$password`\n"
          "⏰ *الوقت:* ${DateTime.now().toString().substring(0, 16)}\n\n"
          "يرجى الدخول لوحة الأدمن لتأكيد الموافقة على التفعيل النهائي.";

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
  static Future<bool> registerUser(String username, String phone, String password) async {
    try {
      await startTempActivation(); // بدء تجربة الـ 3 دقائق فوراً
      await sendTelegramNotification(username, phone, password);

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

      pendingRequests.removeWhere((item) => item['username'] == username || item['phone'] == phone);

      pendingRequests.add({
        'username': username,
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
      return true;
    }
  }

  // --- 4. موافقة الأدمن على التفعيل ---
  static Future<bool> approveUser(String username) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      Map<String, dynamic> data = {};
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded != null && decoded['record'] != null) {
          data = Map<String, dynamic>.from(decoded['record']);
        }
      }

      data['approved_users'] ??= {};
      data['approved_users'][username.trim()] = {
        'approved_at': DateTime.now().toIso8601String(),
        'status': 'active'
      };

      if (data['pending_requests'] is List) {
        List requests = List.from(data['pending_requests']);
        requests.removeWhere((item) => item['username'] == username);
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

      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 5. فحص التفعيل السحابي عند الضغط على "تفعيل الحساب" أو عند تسجيل الدخول ---
  static Future<bool> checkApprovalStatus(String username) async {
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
            if (approved is Map && approved[username.trim()] != null) {
              await setLocalActivated(true); // حفظ التفعيل الدائم
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- 6. تسجيل الدخول من خانة "تسجيل الدخول" ---
  static Future<String> login(String username, String password) async {
    if (username.trim() == "Huzt1998" && password == "Hz19881988") {
      await setAdminLoggedIn(true);
      return "admin";
    }

    // فحص إذا كان التفعيل محلياً أو سحابياً تم قبوله
    bool isApproved = await checkApprovalStatus(username);
    if (isApproved || await isLocalActivated()) {
      return "success";
    }

    return "failed";
  }

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
}
