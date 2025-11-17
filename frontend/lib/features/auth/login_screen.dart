import 'package:flutter/material.dart';
import 'package:frontend/core/services/auth_service.dart';
import 'package:frontend/features/admin/admin_dashboard.dart';
import 'package:frontend/features/teacher/teacher_dashboard.dart';
import 'package:frontend/features/student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authService.login(_loginCodeController.text);

      setState(() {
        _isLoading = false;
      });

      if (user != null && mounted) {
        final role = user['role'];
        // Navigate to the correct dashboard based on the user's role
        switch (role) {
          case 'admin':
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboard()));
            break;
          case 'teacher':
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TeacherDashboard()));
            break;
          case 'student':
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StudentDashboard()));
            break;
        }
      } else {
        setState(() {
          _errorMessage = 'فشل تسجيل الدخول. يرجى التحقق من الكود.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول - المعهد الأول')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('أهلاً بك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _loginCodeController,
                  decoration: const InputDecoration(
                    labelText: 'أدخل كود الدخول الخاص بك',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'هذا الحقل مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        child: const Text('دخول'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
