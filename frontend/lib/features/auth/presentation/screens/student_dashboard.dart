import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة الطالب'),
      ),
      body: const Center(
        child: Text('مرحباً أيها الطالب!'),
      ),
    );
  }
}
