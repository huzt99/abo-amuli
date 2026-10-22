import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String _binId = '6ad894f0ffd5d160537f0188';
  static const String _masterKey = '\$2a\$10\$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';
  static const String _accessKey = '\$2a\$10\$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG';

  static const String _botToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String _chatId = '6590858813';

  static const String _kActivated = 'is_local_activated';
  static const String _kAdminLoggedIn = 'is_admin_logged_in';

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

  // إرسال طلب تفعيل جديد مع حفظ كلمة المرور للعميل
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    await _sendTelegramNotification('🚨 *طلب تفعيل جديد للنظام*\n👤 الاسم: $name\n📞 الهاتف: $phone\n🔑 كلمة المرور المحجوزة: `$password`');
    return await _savePendingUserToCloud(name, phone, password);
  }

  // التأكد من كود التفعيل 11 رقم
  static Future<bool> verifyCode(String phone, String code) async {
    bool isValid = await _verifyUserActivationCode(phone.trim(), code.trim());
    if (isValid) {
      await setLocalActivated(true);
      return true;
    }
    return false;
  }

  // فحص تسجيل الدخول بحساب العميل أو الأدمن
  static Future<String> login(String usernameOrPhone, String password) async {
    if (usernameOrPhone.trim() == 'Huzt1988' && password.trim() == 'Hz19881988') {
      await setAdminLoggedIn(true);
      return 'ADMIN';
    }

    bool isUserValid = await _checkCloudLogin(usernameOrPhone.trim(), password.trim());
    if (isUserValid) {
      await setLocalActivated(true);
      return 'APPROVED';
    }

    return 'INVALID';
  }

  // إعادة تعيين كلمة المرور
  static Future<bool> resetPassword(String phone, String newPassword) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        Map<String, dynamic> record = Map<String, dynamic>.from(body['record'] ?? {});
        List requests = List.from(record['requests'] ?? []);

        bool updated = false;
        for (var req in requests) {
          if (req['phone'] == phone.trim()) {
            req['password'] = newPassword.trim();
            updated = true;
            break;
          }
        }

        if (updated) {
          record['requests'] = requests;
          await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
              'X-Access-Key': _accessKey,
            },
            body: jsonEncode(record),
          );
          await _sendTelegramNotification('🔑 *تعديل كلمة المرور*\n📞 الهاتف: $phone\n🔐 الرمز الجديد: `$newPassword`');
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

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

  static Future<bool> _savePendingUserToCloud(String name, String phone, String password) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      Map<String, dynamic> record = {};
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        record = Map<String, dynamic>.from(body['record'] ?? {});
      }

      List requests = List.from(record['requests'] ?? []);
      requests.removeWhere((item) => item['phone'] == phone);

      requests.add({
        'name': name,
        'phone': phone,
        'password': password,
        'status': 'pending',
        'activation_code': '',
        'date': DateTime.now().toIso8601String(),
      });

      record['requests'] = requests;

      final updateResponse = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
          'X-Access-Key': _accessKey,
        },
        body: jsonEncode(record),
      );

      return updateResponse.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _checkCloudLogin(String phoneOrName, String password) async {
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
          if ((req['phone'] == phoneOrName || req['name'] == phoneOrName) &&
              req['password'] == password &&
              req['status'] == 'approved') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> _verifyUserActivationCode(String phone, String code) async {
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
          if (req['phone'] == phone && req['activation_code'] == code && req['status'] == 'approved') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List requests = body['record']['requests'] ?? [];
        return List<Map<String, dynamic>>.from(requests);
      }
    } catch (_) {}
    return [];
  }

  static Future<String?> approveUserAndGenerateCode(String phone) async {
    try {
      final url = Uri.parse('https://api.jsonbin.io/v3/b/$_binId');
      final response = await http.get(
        url,
        headers: {'X-Master-Key': _masterKey, 'X-Access-Key': _accessKey},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        Map<String, dynamic> record = Map<String, dynamic>.from(body['record'] ?? {});
        List requests = List.from(record['requests'] ?? []);

        String generatedCode = (10000000000 + (DateTime.now().millisecondsSinceEpoch % 90000000000)).toString();
        bool found = false;

        for (var req in requests) {
          if (req['phone'] == phone) {
            req['status'] = 'approved';
            req['activation_code'] = generatedCode;
            found = true;
            break;
          }
        }

        if (found) {
          record['requests'] = requests;
          await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
              'X-Access-Key': _accessKey,
            },
            body: jsonEncode(record),
          );

          await _sendTelegramNotification('✅ *تمت الموافقة وتوليد كود التفعيل*\n📞 العميل: $phone\n🔑 الكود (11 رقم): `$generatedCode`');
          return generatedCode;
        }
      }
    } catch (_) {}
    return null;
  }
}
