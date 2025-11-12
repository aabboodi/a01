import 'package:flutter/material.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلاب'),
      ),
      body: const Center(
        child: Text('سيتم عرض قائمة الطلاب هنا.'),
      ),
    );
  }
}
