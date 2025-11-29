import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/auth_service.dart';
import 'package:frontend/features/admin/admin_dashboard.dart';
import 'package:frontend/features/teacher/teacher_dashboard.dart';
import 'package:frontend/features/student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  LoginScreen({super.key, AuthService? authService})
      : authService = authService ?? AuthService();

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final loginCode = _loginCodeController.text.trim();
    if (loginCode.isEmpty) {
      _showError('الرجاء إدخال كود الدخول');
      return;
    }

    print('🔥🔥🔥 [LOGIN_SCREEN] Starting login with code: $loginCode');
    setState(() => _isLoading = true);

    try {
      print('🔥🔥🔥 [LOGIN_SCREEN] Calling authService.login...');
      final userData = await widget.authService.login(loginCode);
      print('🔥🔥🔥 [LOGIN_SCREEN] Login successful! UserData: $userData');
      print('🔥🔥🔥 [LOGIN_SCREEN] Role extracted: ${userData['role']}');
      
      if (mounted) {
        print('🔥🔥🔥 [LOGIN_SCREEN] Navigating to dashboard for role: ${userData['role']}');
        _navigateToDashboard(userData['role'], userData);
      } else {
        print('🔥🔥🔥 [LOGIN_SCREEN] Widget not mounted, skipping navigation');
      }
    } catch (e) {
      print('🔥🔥🔥 [LOGIN_SCREEN] Login failed with error: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role, Map<String, dynamic> userData) {
    print('🔥🔥🔥 [NAVIGATION] _navigateToDashboard called with role: $role');
    Widget page;
    switch (role) {
      case 'admin':
        print('🔥🔥🔥 [NAVIGATION] Matched admin role, creating AdminDashboard');
        page = const AdminDashboard();
        break;
      case 'teacher':
        print('🔥🔥🔥 [NAVIGATION] Matched teacher role, creating TeacherDashboard');
        page = TeacherDashboard(userData: userData);
        break;
      case 'student':
        print('🔥🔥🔥 [NAVIGATION] Matched student role, creating StudentDashboard');
        page = StudentDashboard(userData: userData);
        break;
      default:
        print('🔥🔥🔥 [NAVIGATION] Unknown role: $role');
        _showError('دور المستخدم غير معروف: $role');
        return;
    }

    print('🔥🔥🔥 [NAVIGATION] Pushing route to: ${page.runtimeType}');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
    print('🔥🔥🔥 [NAVIGATION] Navigation completed');
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
