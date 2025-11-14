import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/auth/presentation/screens/student_classroom_screen.dart';

class StudentDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StudentDashboard({super.key, required this.userData});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ClassService _classService = ClassService();
  Future<List<dynamic>>? _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _classService.getAllClasses();
  }

  void _navigateToClassroom(dynamic aClass) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentClassroomScreen(
          classData: aClass,
          userData: widget.userData, // Pass user data
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً, ${widget.userData['full_name']}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد فصول متاحة حالياً.'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final aClass = classes[index];
              return ListTile(
                title: Text(aClass['class_name']),
                subtitle: const Text('اضغط للدخول إلى الصف'),
                onTap: () => _navigateToClassroom(aClass),
              );
            },
          );
        },
      ),
    );
  }
}
