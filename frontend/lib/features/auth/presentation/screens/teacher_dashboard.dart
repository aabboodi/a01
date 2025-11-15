import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/auth/presentation/screens/teacher_classroom_screen.dart';
import 'package:frontend/features/auth/presentation/screens/manage_grades_screen.dart';
import 'package:frontend/features/auth/presentation/screens/archive_screen.dart';
import 'package:frontend/features/auth/application/services/permission_service.dart';

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TeacherDashboard({super.key, required this.userData});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ClassService _classService = ClassService();
  final PermissionService _permissionService = PermissionService();
  Future<List<dynamic>>? _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _classService.getClassesByTeacher(widget.userData['user_id']);
  }

  Future<void> _navigateToClassroom(dynamic aClass) async {
    final permissionsGranted = await _permissionService.requestClassroomPermissions();
    if (permissionsGranted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => TeacherClassroomScreen(classData: aClass)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera and microphone permissions are required to enter the classroom.')),
      );
    }
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
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final aClass = classes[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aClass['class_name'],
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.videocam,
                            label: 'دخول',
                            onPressed: () => _navigateToClassroom(aClass),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.grade,
                            label: 'العلامات',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ManageGradesScreen(classData: aClass)),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.archive,
                            label: 'الأرشيف',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ArchiveScreen(classData: aClass)),
                              );
                            },
                          ),
                        ],
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

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Theme.of(context).primaryColor),
          iconSize: 30,
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
        },
      ),
    );
  }
}
