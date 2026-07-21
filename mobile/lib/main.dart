// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Menggunakan jalur relatif langsung ke folder screens

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi DAPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
    );
  }
}