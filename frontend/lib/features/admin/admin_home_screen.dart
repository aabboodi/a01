import 'package:flutter/material.dart';
import 'package:frontend/features/admin/manage_classes_screen.dart';
import 'package:frontend/features/admin/manage_students_screen.dart';
import 'package:frontend/features/admin/manage_teachers_screen.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/auth/application/services/user_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final UserService _userService = UserService();
  final ClassService _classService = ClassService();

  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    try {
      final students = await _userService.getUsersByRole('student');
      final teachers = await _userService.getUsersByRole('teacher');
      final classes = await _classService.getAllClasses();
      return {
        'students': students.length,
        'teachers': teachers.length,
        'classes': classes.length,
      };
    } catch (e) {
      // Return zeros or handle error appropriately
      return {'students': 0, 'teachers': 0, 'classes': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Failed to load dashboard stats.'));
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص النظام',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, // Make cards slightly larger
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'إدارة الطلاب',
                    stats['students']!,
                    Icons.person,
                    Colors.blue,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen())),
                  ),
                  _buildStatCard(
                    'إدارة المدرسين',
                    stats['teachers']!,
                    Icons.school,
                    Colors.orange,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageTeachersScreen())),
                  ),
                  _buildStatCard(
                    'إدارة الصفوف',
                    stats['classes']!,
                    Icons.class_,
                    Colors.green,
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageClassesScreen())),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
