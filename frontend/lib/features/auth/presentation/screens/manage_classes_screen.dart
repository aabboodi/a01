import 'package:flutter/material.dart';

class ManageClassesScreen extends StatelessWidget {
  const ManageClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الصفوف'),
      ),
      body: const Center(
        child: Text('سيتم عرض قائمة الصفوف هنا.'),
      ),
    );
  }
}
