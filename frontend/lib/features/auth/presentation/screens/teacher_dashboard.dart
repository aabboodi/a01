import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/auth/presentation/screens/teacher_classroom_screen.dart';
import 'package:frontend/features/auth/presentation/screens/manage_grades_screen.dart';
import 'package:frontend/features/auth/presentation/screens/archive_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TeacherDashboard({super.key, required this.userData});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ClassService _classService = ClassService();
  Future<List<dynamic>>? _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _classService.getClassesByTeacher(widget.userData['user_id']);
  }

  void _navigateToClassroom(dynamic aClass) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TeacherClassroomScreen(classData: aClass)),
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
            return const Center(child: Text('لم يتم تعيين أي صفوف لك بعد.'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final aClass = classes[index];
              return ListTile(
                title: Text(aClass['class_name']),
                subtitle: const Text('اختر إجراء'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grade),
                      tooltip: 'إدارة العلامات',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => ManageGradesScreen(classData: aClass)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      tooltip: 'الدخول إلى الصف',
                      onPressed: () => _navigateToClassroom(aClass),
                    ),
                      IconButton(
                        icon: const Icon(Icons.archive),
                        tooltip: 'الأرشيف',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ArchiveScreen(classData: aClass)),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
