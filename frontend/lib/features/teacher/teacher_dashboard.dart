import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/teacher/teacher_classroom_screen.dart';
import 'package:frontend/features/teacher/manage_grades_screen.dart';
import 'package:frontend/features/admin/archive_screen.dart';

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
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture = _classService.getClassesForTeacher(widget.userData['userId']);
    });
  }

  void _navigateToGrades(Map<String, dynamic> classData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageGradesScreen(classData: classData),
      ),
    );
  }

  void _navigateToArchive(Map<String, dynamic> classData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArchiveScreen(classData: classData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم المدرس: ${widget.userData['loginCode']}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد فصول دراسية متاحة.'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    classData['class_name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text('ID: ${classData['class_id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        child: const Text('دخول الفصل'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TeacherClassroomScreen(
                                classData: classData,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.grade),
                        onPressed: () => _navigateToGrades(classData),
                        tooltip: 'إدارة الدرجات',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.archive),
                        onPressed: () => _navigateToArchive(classData),
                        tooltip: 'الأرشيف',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
