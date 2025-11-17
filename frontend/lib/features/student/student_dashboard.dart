import 'package:flutter/material.dart';
class StudentDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const StudentDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Student: ${userData['full_name']}')));
}
