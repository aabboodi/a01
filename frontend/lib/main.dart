import 'package:flutter/material.dart';
import 'package:frontend/features/auth/login_screen.dart';

void main() {
  runApp(const TheFirstInstituteApp());
}

class TheFirstInstituteApp extends StatelessWidget {
  const TheFirstInstituteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المعهد الأول',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
