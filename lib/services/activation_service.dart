import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // إرسال طلب تفعيل جديد
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  // التحقق من كود التفعيل
  static Future<bool> verifyCode(String phone, String code) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
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
      await Future.delayed(const Duration(seconds: 1));
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

  // إعادة تعيين كلمة المرور
  static Future<bool> resetPassword(String phone, String newPassword) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  // جلب الطلبات المعلقة (للوحة التحكم)
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {'name': 'مستخدم تجريبي', 'phone': '07800000000', 'date': '2026-10-22'}
      ];
    } catch (e) {
      return [];
    }
  }

  // الموافقة على المستخدم وتوليد الكود
  static Future<String?> approveUserAndGenerateCode(String phone) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return '123456';
    } catch (e) {
      return null;
    }
  }
}
