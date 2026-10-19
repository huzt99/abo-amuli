import 'package:flutter/material.dart';
import 'screens/pos_screen.dart';

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
        fontFamily: 'Cairo', // الخط العربي العام
      ),
      // جعل شاشة نقطة البيع هي الواجهة الافتتاحية عند فتح التطبيق
      home: const PosScreen(),
    );
  }
}
