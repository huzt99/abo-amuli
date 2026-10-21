import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String binId = '6ad894f0ffd5d160537f0188';
  static const String masterKey = r'$2a$10$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';
  static const String accessKey = r'$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG';

  static const String telegramBotToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String telegramChatId = '6590858813';

  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_activated') ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', value);
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin_logged') ?? false;
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged', value);
  }

  // --- جلب البيانات مع إرجاع الخطأ الحقيقي إن وجد ---
  static Future<List<Map<String, dynamic>>> fetchUsersFromCloud() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId/latest'),
        headers: {
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
      ).timeout(const Duration(seconds: 10));

      print('JSONBin GET Status: ${response.statusCode}');
      print('JSONBin GET Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        if (decoded.containsKey('record')) {
          final record = decoded['record'];
          if (record is Map && record.containsKey('users') && record['users'] is List) {
            List list = record['users'];
            return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } else if (record is List) {
            return record.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      } else {
        print('خطأ سحابة غير متوقع: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('استثناء خطأ الشبكة/السحابة: $e');
    }
    return [];
  }

  // --- تسجيل مستخدم جديد مع فحص الرد ---
  static Future<bool> registerUserDual({required String username, required String email}) async {
    try {
      List<Map<String, dynamic>> users = await fetchUsersFromCloud();
      
      users.removeWhere((u) => u['username'] == username);
      users.add({
        'username': username,
        'email': email,
        'status': 'معلق ⏳',
        'date': DateTime.now().toString().split('.')[0],
      });

      final response = await http.put(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
        body: jsonEncode({'users': users}),
      ).timeout(const Duration(seconds: 10));

      print('JSONBin PUT Status: ${response.statusCode}');
      print('JSONBin PUT Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('استثناء تسجيل السحابة: $e');
      return false;
    }
  }

  // --- فحص التفعيل ---
  static Future<bool> checkUserActivationDual(String username) async {
    List<Map<String, dynamic>> users = await fetchUsersFromCloud();
    for (var u in users) {
      if (u['username'] == username && (u['status'] == 'تم التفعيل ✅' || u['status'] == 'مفعل')) {
        await setLocalActivated(true);
        return true;
      }
    }
    return false;
  }

  // --- موافقة الأدمن وتحديث السحابة ---
  static Future<bool> approveUserDual(String username) async {
    try {
      List<Map<String, dynamic>> users = await fetchUsersFromCloud();
      for (var u in users) {
        if (u['username'] == username) {
          u['status'] = 'تم التفعيل ✅';
        }
      }

      final response = await http.put(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
        body: jsonEncode({'users': users}),
      ).timeout(const Duration(seconds: 10));

      print('Approve PUT Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('استثناء الموافقة: $e');
      return false;
    }
  }

  // --- إرسال التليجرام ---
  static Future<bool> sendTelegramActivationRequest({
    required String username,
    required String email,
  }) async {
    final String textMsg = '🚨 طلب تفعيل برنامج جديد!\n\n'
        '👤 المستخدم: $username\n'
        '📧 البريد: $email\n'
        '⏱ الوقت: ${DateTime.now().toString().split('.')[0]}';

    try {
      final url = Uri.parse('https://api.telegram.org/bot$telegramBotToken/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': telegramChatId,
          'text': textMsg,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Telegram Response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('استثناء التليجرام: $e');
      return false;
    }
  }
}
