import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  // إعدادات JSONBin
  static const String _binId = '6ad894f0ffd5d160537f0188';
  static const String _masterKey = '\$2a\$10\$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';
  static const String _accessKey = '\$2a\$10\$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG';

  // إعدادات التليجرام
  static const String _botToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String _chatId = '6590858813';

  // المفاتيح المحلية
  static const String _kActivated = 'is_local_activated';
  static const String _kAdminLoggedIn = 'is_admin_logged_in';
  static const String _kUserPhone = 'user_phone_number';

  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kActivated) ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActivated, value);
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAdminLoggedIn) ?? false;
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdminLoggedIn, value);
  }

  // 1️⃣ إرسال طلب تفعيل جديد بدون تفعيل تلقائي
  static Future<bool> sendActivationRequest(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserPhone, phone.trim());

    // إرسال تنبيه للتليجرام فوراً
    await _sendTelegramNotification('🚨 *طلب تفعيل جديد للنظام*\n👤 الاسم: $name\n📞 الهاتف: $phone\n\nيرجى الدخول بحساب الأدمن للموافقة.');

    // حفظ الطلب بحالة "معلق" في السحاب
    return await _savePendingUserToCloud(name, phone);
  }

  // 2️⃣ تسجيل الدخول وتأكد العميل هل تمت الموافقة عليه أم لا
  static Future<String> loginOrCheckApproval(String identifier, String password) async {
    // تسجيل دخول الأدمن
    if (identifier.trim() == 'huzt.m1@gmail.com' && password.trim() == '20819921992') {
      await setAdminLoggedIn(true);
      return 'ADMIN';
    }

    // فحص موافقة العميل سحابياً
    bool isApproved = await _checkUserApprovalStatus(identifier.trim());
    if (isApproved) {
      await setLocalActivated(true);
      return 'APPROVED';
    }

    return 'PENDING';
  }

  // إرسال تنبيه تليجرام
  static Future<void> _sendTelegramNotification(String message) async {
    try {
      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );
    } catch (_) {}
  }

  // حفظ بيانات العميل المعلق في JSONBin
  static Future<bool> _savePendingUserToCloud(String name, String phone) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      Map<String, dynamic> currentData = {};
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        currentData = Map<String, dynamic>.from(body['record'] ?? {});
      }

      List requests = currentData['requests'] ?? [];
      requests.add({
        'name': name,
        'phone': phone,
        'status': 'pending', // معلق
        'date': DateTime.now().toIso8601String(),
      });

      currentData['requests'] = requests;

      final updateResponse = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
          'X-Access-Key': _accessKey,
        },
        body: jsonEncode(currentData),
      );

      return updateResponse.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // التحقق هل تمت موافقة الأدمن على العميل
  static Future<bool> _checkUserApprovalStatus(String phone) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List requests = body['record']['requests'] ?? [];
        for (var req in requests) {
          if (req['phone'] == phone && req['status'] == 'approved') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }
}
