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
      final user = await _authService.login(_loginCodeController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user != null) {
        Widget destination;
        switch (user['role']) {
          case 'admin':
            destination = const AdminDashboard();
            break;
          case 'teacher':
            destination = TeacherDashboard(userData: user);
            break;
          case 'student':
            destination = StudentDashboard(userData: user);
            break;
          default: return;
        }
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
      } else {
        setState(() => _errorMessage = 'Login failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('المعهد الأول', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _loginCodeController,
                  decoration: const InputDecoration(labelText: 'أدخل كود الدخول', border: OutlineInputBorder()),
                  validator: (v) => (v ?? '').isEmpty ? 'الحقل مطلوب' : null,
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _login, child: const Text('دخول')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
