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

  // الرمز القياسي
  static const String _validCode = '20319920';

  // المفاتيح المحلية
  static const String _kActivated = 'is_local_activated';
  static const String _kAdminLoggedIn = 'is_admin_logged_in';

  // التحقق من التفعيل المحلي
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kActivated) ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActivated, value);
  }

  // التحقق من دخول المشرف
  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAdminLoggedIn) ?? false;
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdminLoggedIn, value);
  }

  // تسجيل طلب جديد والتفعيل
  static Future<bool> registerAndActivate(String name, String phone, String code) async {
    if (code.trim() != _validCode) {
      return false;
    }

    // حفظ التفعيل محلياً
    await setLocalActivated(true);

    // إرسال إشعار تليجرام
    _sendTelegramNotification('طلب تفعيل جديد:\nالاسم: $name\nالهاتف: $phone');

    // حفظ البيانات سحابياً
    _saveUserToCloud(name, phone);

    return true;
  }

  // تسجيل الدخول (للعملاء أو المشرف)
  static Future<bool> login(String email, String password) async {
    // حساب المشرف الرئيسي
    if (email.trim() == 'huzt.m1@gmail.com' && password.trim() == '20819921992') {
      await setAdminLoggedIn(true);
      return true;
    }

    // التحقق من التفعيل المحلي
    bool activated = await isLocalActivated();
    return activated;
  }

  // إرسال إشعار تليجرام
  static Future<void> _sendTelegramNotification(String message) async {
    try {
      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
        }),
      );
    } catch (_) {}
  }

  // حفظ بيانات المستخدم سحابياً
  static Future<void> _saveUserToCloud(String name, String phone) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {
          'X-Master-Key': _masterKey,
          'X-Access-Key': _accessKey,
        },
      );

      Map<String, dynamic> currentData = {};
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        currentData = Map<String, dynamic>.from(body['record'] ?? {});
      }

      List users = currentData['users'] ?? [];
      users.add({
        'name': name,
        'phone': phone,
        'date': DateTime.now().toIso8601String(),
      });

      currentData['users'] = users;

      await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
          'X-Access-Key': _accessKey,
        },
        body: jsonEncode(currentData),
      );
    } catch (_) {}
  }
}
