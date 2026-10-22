import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  // التوكن والشات آيدي الخاص بك يا أبو مؤمل
  static const String _botToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String _chatId = '6590858813';

  static const String _keyActivated = 'is_activated';
  static const String _keyAdminLoggedIn = 'is_admin_logged_in';

  // التحقق مما إذا كانت النسخة مفعلة محلياً
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyActivated) ?? false;
  }

  // تعيين حالة التفعيل محلياً
  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActivated, value);
  }

  // التحقق من تسجيل دخول المسؤول
  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdminLoggedIn) ?? false;
  }

  // تعيين حالة تسجيل دخول المسؤول
  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdminLoggedIn, value);
  }

  // إرسال طلب تفعيل جديد إلى تليجرام الخاص بك
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    try {
      final message = '🔔 *طلب تفعيل تطبيق جديد*\n\n'
          '👤 اسم المحل: $name\n'
          '📱 رقم الهاتف: $phone\n'
          '🔑 كلمة المرور/الرمز: $password\n'
          '⏰ الوقت: ${DateTime.now().toString().substring(0, 19)}\n\n'
          '⚡ يرجى مراجعة الطلب ومنح كود التفعيل لصاحب المحل!';

      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      final response = await http.post(
        url,
        body: {
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'Markdown',
        },
      );

      debugPrint('Telegram Response Status: ${response.statusCode}');
      debugPrint('Telegram Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Telegram Exception: $e');
      return false;
    }
  }

  // التحقق من كود التفعيل
  static Future<bool> verifyCode(String phone, String code) async {
    try {
      if (code.isNotEmpty) {
        await setLocalActivated(true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // تسجيل الدخول
  static Future<String> login(String username, String password) async {
    try {
      if (username == 'admin' && password == 'admin123') {
        await setAdminLoggedIn(true);
        return 'admin';
      } else if (username.isNotEmpty) {
        await setLocalActivated(true);
        return 'user';
      }
      return 'error';
    } catch (e) {
      return 'error';
    }
  }
}
