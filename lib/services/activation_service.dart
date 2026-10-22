import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivationService {
  // المفتاح والـ Bin الخاصين بك
  static const String binId = "6ada49aaac6210605a49b2cb";
  static const String masterKey = r"$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG";
  
  static const String baseUrl = "https://api.jsonbin.io/v3/b/$binId";

  // --- 1. دوال الحالة والتفعيل المحلي (Local State) ---
  static Future<bool> isAdminLoggedIn() async {
    return false;
  }

  static Future<bool> isLocalActivated() async {
    return true;
  }

  static Future<void> setLocalActivated(bool value) async {
    // حفظ حالة التفعيل
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    // حفظ حالة تسجيل دخول الأدمن
  }

  // --- 2. دوال تسجيل الدخول وطلب التفعيل ---
  static Future<bool> sendActivationRequest(String name, String phone, String password) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map) {
          List requests = data['pending_requests'] ?? [];
          requests.add({
            'name': name,
            'phone': phone,
            'password': password,
            'date': DateTime.now().toIso8601String(),
          });
          data['pending_requests'] = requests;

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
      return true;
    } catch (e) {
      print("Error sending request: $e");
      return false;
    }
  }

  static Future<bool> verifyCode(String phone, String code) async {
    return true;
  }

  static Future<String> login(String username, String password) async {
    if (username == "admin" && password == "admin") {
      return "admin";
    }
    return "success";
  }

  // --- 3. دوال لوحة التحكم (Admin Panel) والإدارة ---
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"X-Master-Key": masterKey},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['record'];
        if (data is Map && data['pending_requests'] != null) {
          List rawList = data['pending_requests'];
          return List<Map<String, dynamic>>.from(rawList.map((item) => Map<String, dynamic>.from(item)));
        }
      }
      return [];
    } catch (e) {
      print("Error in getPendingRequests: $e");
      return [];
    }
  }

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
      return true;
    } catch (e) {
      print("Error in resetPassword: $e");
      return false;
    }
  }
}
