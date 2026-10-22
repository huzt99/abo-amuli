import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivationService {
  // المفتاح والـ Bin الجديدان اللذان قمت بإنشائهما
  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  
  static const String baseUrl = "https://api.jsonbin.io/v3/b/$binId";

  // 1. دالة إعادة تعيين كلمة المرور
  static Future<bool> resetPassword(String phone, String newPass) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map) {
          data['users'] ??= {};
          if (data['users'][phone] != null) {
            data['users'][phone]['password'] = newPass;

            await http.put(
              Uri.parse(baseUrl),
              headers: {
                "Content-Type": "application/json",
                "X-Master-Key": masterKey,
              },
              body: jsonEncode(data),
            );
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("Error in resetPassword: $e");
      return false;
    }
  }

  // 2. دالة جلب طلبات التفعيل المعلقة
  static Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map && data['pending_requests'] != null) {
          return List<dynamic>.from(data['pending_requests']);
        }
      }
      return [];
    } catch (e) {
      print("Error in getPendingRequests: $e");
      return [];
    }
  }

  // 3. دالة الموافقة على المستخدم وتوليد كود التفعيل
  static Future<String?> approveUserAndGenerateCode(String phone) async {
    try {
      String generatedCode = "POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map) {
          data['approved_users'] ??= {};
          data['approved_users'][phone] = {
            'code': generatedCode,
            'approved_at': DateTime.now().toIso8601String(),
          };

          await http.put(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
              "X-Master-Key": masterKey,
            },
            body: jsonEncode(data),
          );

          return generatedCode;
        }
      }
      return generatedCode;
    } catch (e) {
      print("Error in approveUserAndGenerateCode: $e");
      return null;
    }
  }
}
