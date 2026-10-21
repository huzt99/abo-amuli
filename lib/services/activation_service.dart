import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivationService {
  static const String telegramBotToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String telegramChatId = '6590858813';

  // قائمة الحسابات المعلقة المؤقتة
  static final List<Map<String, String>> _registeredUsers = [];

  static Future<void> savePendingUser({required String username, required String email}) async {
    _registeredUsers.add({
      'username': username,
      'email': email,
      'status': 'معلق ⏳',
    });
  }

  static Future<List<Map<String, String>>> getPendingUsers() async {
    return _registeredUsers;
  }

  static Future<void> approveUser(String username) async {
    for (var u in _registeredUsers) {
      if (u['username'] == username) {
        u['status'] = 'تم التفعيل ✅';
      }
    }
  }

  static Future<bool> sendTelegramActivationRequest({
    required String fullName,
    required String email,
    required String username,
    required String phone,
  }) async {
    final String plainTextMessage = '''
🚨 طلب تفعيل برنامج POS جديد!
━━━━━━━━━━━━━━━━━━
👤 حساب الزبون: $username
📧 البريد الإلكتروني: $email
⏱ التوقيت: ${DateTime.now().toString().split('.')[0]}
━━━━━━━━━━━━━━━━━━
⚙️ يرجى تسجيل الدخول بحساب الأدمن (huzt.m1@gmail.com) للموافقة.
''';

    try {
      final url = Uri.parse('https://api.telegram.org/bot$telegramBotToken/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': telegramChatId,
          'text': plainTextMessage,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
