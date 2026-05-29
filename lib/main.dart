import 'package:absensi_mobile/screen/dashboard.dart';
import 'package:flutter/material.dart';
import 'screen/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InternTrack',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      ),

      // REDIRECT KE LOGIN
      home: const LoginPage(),
    );
  }
}