import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivationService {
  static const String telegramBotToken = '8985397948:AAHqEZ3d-VP-aDUTe6yP5ndFbaKevMVA_1I';
  static const String telegramChatId = '6590858813';

  static const String adminEmail = 'huzt.m1@gmail.com';
  static const String adminUsername = 'huzt1992';
  static const String adminPassword = '20819921992';

  static Future<bool> sendTelegramActivationRequest({
    required String fullName,
    required String email,
    required String username,
    required String phone,
  }) async {
    final String message = '''
🚨 **طلب تفعيل برنامج POS جديد!**
━━━━━━━━━━━━━━━━━━
👤 **اسم الزبون:** $fullName
📧 **البريد الإلكتروني:** $email
🆔 **اسم المستخدم:** $username
📞 **رقم الهاتف:** $phone
⏱ **تاريخ الطلب:** ${DateTime.now().toString().split('.')[0]}
━━━━━━━━━━━━━━━━━━
⚙️ **الإجراء المطلوب:** يرجى فتح حساب الأدمن (`huzt1992`) للموافقة والتفعيل.
''';

    try {
      final url = Uri.parse('https://api.telegram.org/bot$telegramBotToken/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': telegramChatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في إرسال إشعار التلغرام: $e');
      return false;
    }
  }
}
