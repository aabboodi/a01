import 'package:flutter/material.dart';
class TeacherDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const TeacherDashboard({super.key, required this.userData});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Teacher: ${userData['full_name']}')));
}
