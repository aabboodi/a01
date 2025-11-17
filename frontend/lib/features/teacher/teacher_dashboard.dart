import 'package:flutter/material.dart';
import 'package:frontend/core/services/auth_service.dart';
import 'package:frontend/core/services/class_service.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/teacher/teacher_classroom_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
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

      final classes = await _classService.getAllClasses(); // Assuming backend filters by teacher
      setState(() {
        _currentUser = user;
        _classes = classes;
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
        title: Text(_currentUser != null ? 'مرحباً، ${_currentUser!['full_name']}' : 'لوحة تحكم المدرس'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('خطأ: $_error'));
    if (_classes.isEmpty) return const Center(child: Text('ليس لديك أي فصول دراسية.'));

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
              Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherClassroomScreen(classData: aClass)));
            },
          ),
        );
      },
    );
  }
}
