import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String binId = '6ad894f0ffd5d160537f0188';
  static const String masterKey = r'$2a$10$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';
  static const String accessKey = r'$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG';

  static const String telegramBotToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String telegramChatId = '6590858813';

  // --- التخزين المحلي ---
  static Future<bool> isLocalActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_activated') ?? false;
  }

  static Future<void> setLocalActivated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', value);
  }

  // --- التعامل مع السحابة JSONBin.io ---
  static Future<List<Map<String, dynamic>>> fetchUsersFromCloud() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId/latest'),
        headers: {
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = data['record']['users'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('خطأ جلب السحابة: $e');
    }
    return [];
  }

  static Future<bool> registerUserDual({required String username, required String email}) async {
    try {
      List<Map<String, dynamic>> users = await fetchUsersFromCloud();
      
      bool exists = users.any((u) => u['username'] == username);
      if (!exists) {
        users.add({
          'username': username,
          'email': email,
          'status': 'معلق ⏳',
        });

        final response = await http.put(
          Uri.parse('https://api.jsonbin.io/v3/b/$binId'),
          headers: {
            'Content-Type': 'application/json',
            'X-Master-Key': masterKey,
          },
          body: jsonEncode({'users': users}),
        );
        return response.statusCode == 200;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkUserActivationDual(String username) async {
    List<Map<String, dynamic>> users = await fetchUsersFromCloud();
    for (var u in users) {
      if (u['username'] == username && u['status'] == 'تم التفعيل ✅') {
        await setLocalActivated(true);
        return true;
      }
    }
    return false;
  }

  // موافقة الأدمن وحفظها في السحابة دائمياً
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
        },
        body: jsonEncode({'users': users}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في الموافقة السحابية: $e');
      return false;
    }
  }

  // --- إرسال إشعار التليجرام الفوري ---
  static Future<bool> sendTelegramActivationRequest({
    required String username,
    required String email,
  }) async {
    final String textMessage = '🚨 طلب تفعيل برنامج جديد!\n\n'
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
          'text': textMessage,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في التليجرام: $e');
      return false;
    }
  }
}
