import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class CloudService {
  // المفاتيح والـ Bin الخاصة بك
  static const String binId = '6ad894f0ffd5d160537f0188';
  static const String masterKey = r'$2a$10$4Tc0iksgy9.hUeH4n5LeCewNlWf46yUlr5vu5DfgU3KVbieJF5OvK';
  static const String accessKey = r'$2a$10$ziZZDkZgcVtijBUQfD.L2uCwX5SaUbNN5dNTohrPgPgadg0CImSYG';

  // 1. رفع البيانات إلى السحابة (نسخ احتياطي)
  static Future<bool> uploadBackup() async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final sales = await DatabaseHelper.instance.getAllSales();

      final dataToUpload = {
        'last_updated': DateTime.now().toIso8601String(),
        'products': products,
        'sales': sales,
      };

      final response = await http.put(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
        body: jsonEncode(dataToUpload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في الرفع السحابي: $e');
      return false;
    }
  }

  // 2. سحب واستعادة البيانات من السحابة (دمج واسترجاع)
  static Future<bool> downloadAndRestore() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jsonbin.io/v3/b/$binId/latest'),
        headers: {
          'X-Master-Key': masterKey,
          'X-Access-Key': accessKey,
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final record = resData['record'];

        if (record != null && record['products'] != null) {
          List products = record['products'];
          for (var prod in products) {
            await DatabaseHelper.instance.insertOrUpdateProduct(prod);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('خطأ في السحب السحابي: $e');
      return false;
    }
  }
}
