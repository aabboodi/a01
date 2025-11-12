import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/screens/manage_teachers_screen.dart';
import 'package:frontend/features/auth/presentation/screens/manage_students_screen.dart';
import 'package:frontend/features/auth/presentation/screens/manage_classes_screen.dart';
import 'package:frontend/features/auth/presentation/screens/archive_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // This will hold the main content of the dashboard
  Widget _selectedScreen = const Center(child: Text('الرجاء تحديد قسم من القائمة'));

  void _navigateTo(Widget screen) {
    Navigator.of(context).pop(); // Close the drawer
    setState(() {
      _selectedScreen = screen;
    });
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'القائمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('إدارة المدرسين'),
              onTap: () => _navigateTo(const ManageTeachersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('إدارة الطلاب'),
              onTap: () => _navigateTo(const ManageStudentsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('إدارة الصفوف'),
              onTap: () => _navigateTo(const ManageClassesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('الأرشيف'),
              onTap: () => _navigateTo(const ArchiveScreen()),
            ),
          ],
        ),
      ),
      body: _selectedScreen,
    );
  }
}
