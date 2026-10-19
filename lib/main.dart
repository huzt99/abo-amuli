import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // استدعاء لوحة التحكم

void main() {
  runApp(const PosSystemApp());
}

class PosSystemApp extends StatelessWidget {
  const PosSystemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام نقاط البيع - POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      // جعل لوحة التحكم هي الواجهة الرئيسية عند بدء التطبيق
      home: const DashboardScreen(),
    );
  }
}
