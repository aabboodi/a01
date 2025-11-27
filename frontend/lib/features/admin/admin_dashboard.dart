import 'package:flutter/material.dart';
import 'package:frontend/features/admin/manage_teachers_screen.dart';
import 'package:frontend/features/admin/manage_students_screen.dart';
import 'package:frontend/features/admin/manage_classes_screen.dart';
import 'package:frontend/features/admin/archive_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/admin/admin_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/admin/class_provider.dart';
import 'package:frontend/features/admin/admin_home_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> db91d413c61a8bdfd5cfbff589dc489443652404
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'تسجيل الخروج',
          ),
        ],
<<<<<<< HEAD
=======
=======
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardProvider(),
      child: Consumer<AdminDashboardProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('لوحة تحكم المدير'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                  tooltip: 'تسجيل الخروج',
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Text('القائمة',
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('الرئيسية'),
                    onTap: () {
                      Navigator.of(context).pop();
                      provider.navigateTo(AdminHomeScreen());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('إدارة المدرسين'),
                    onTap: () {
                      Navigator.of(context).pop();
                      provider.navigateTo(const ManageTeachersScreen());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('إدارة الطلاب'),
                    onTap: () {
                      Navigator.of(context).pop();
                      provider.navigateTo(const ManageStudentsScreen());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.class_),
                    title: const Text('إدارة الصفوف'),
                    onTap: () {
                      Navigator.of(context).pop();
                      provider.navigateTo(const ManageClassesScreen());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.archive),
                    title: const Text('الأرشيف'),
                    onTap: () {
                      Navigator.of(context).pop();
                      provider.navigateTo(const _ClassSelectionScreen());
                    },
                  ),
                ],
              ),
            ),
            body: provider.selectedScreen,
          );
        },
>>>>>>> 42825131257bbb6730ec37d1c19196ece363f065
>>>>>>> db91d413c61a8bdfd5cfbff589dc489443652404
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('القائمة',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الرئيسية'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('إدارة المدرسين'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageTeachersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('إدارة الطلاب'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageStudentsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('إدارة الصفوف'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageClassesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('الأرشيف'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ClassSelectionScreen()));
              },
            ),
          ],
        ),
      ),
      body: const AdminHomeScreen(),
    );
  }
}

class _ClassSelectionScreen extends StatelessWidget {
  const _ClassSelectionScreen();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Select a Class to View Archive')),
        body: Consumer<ClassProvider>(
          builder: (context, provider, child) {
            switch (provider.state) {
              case ClassListState.loading:
                return const Center(child: CircularProgressIndicator());
              case ClassListState.error:
                return Center(
                    child: Text(
                        provider.errorMessage ?? 'An unknown error occurred.'));
              case ClassListState.loaded:
                if (provider.classes.isEmpty) {
                  return const Center(child: Text('No classes found.'));
                }
                return ListView.builder(
                  itemCount: provider.classes.length,
                  itemBuilder: (context, index) {
                    final classData = provider.classes[index];
                    return ListTile(
                      title: Text(classData['class_name']),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ArchiveScreen(classData: classData),
                          ),
                        );
                      },
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
