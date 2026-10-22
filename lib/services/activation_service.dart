import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
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
}
