import 'package:flutter/material.dart';
import 'package:frontend/core/services/auth_service.dart';
import 'package:frontend/core/services/class_service.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/student/student_classroom_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final ClassService _classService = ClassService();
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      // Note: Backend needs to provide an endpoint for student's classes.
      // For now, we'll fetch all and filter client-side as a placeholder.
      final allClasses = await _classService.getAllClasses();
      final studentId = user['user_id'];
      final enrolledClasses = allClasses.where((c) {
        return c['enrollments']?.any((e) => e['student_id'] == studentId) ?? false;
      }).toList();

      setState(() {
        _currentUser = user;
        _classes = enrolledClasses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null ? 'مرحباً، ${_currentUser!['full_name']}' : 'لوحة تحكم الطالب'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('خطأ: $_error'));
    if (_classes.isEmpty) return const Center(child: Text('أنت غير مسجل في أي فصول دراسية.'));

    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final aClass = _classes[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(aClass['class_name']),
             subtitle: Text('ID: ${aClass['class_id']}'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StudentClassroomScreen(classData: aClass)));
            },
          ),
        );
      },
    );
  }
}
