import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/auth_service.dart';
import 'package:frontend/features/admin/admin_dashboard.dart';
import 'package:frontend/features/teacher/teacher_dashboard.dart';
import 'package:frontend/features/student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCodeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    final loginCode = _loginCodeController.text.trim();
    if (loginCode.isEmpty) {
      _showError('الرجاء إدخال كود الدخول');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await _authService.login(loginCode);
      if (mounted) {
        _navigateToDashboard(userData['role'], userData);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role, Map<String, dynamic> userData) {
    Widget page;
    switch (role) {
      case 'admin':
        page = const AdminDashboard();
        break;
      case 'teacher':
        page = TeacherDashboard(userData: userData);
        break;
      case 'student':
        page = StudentDashboard(userData: userData);
        break;
      default:
        _showError('دور المستخدم غير معروف: $role');
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _loginCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'المعهد الأول',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _loginCodeController,
                decoration: const InputDecoration(
                  labelText: 'كود الدخول',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('تسجيل الدخول'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
