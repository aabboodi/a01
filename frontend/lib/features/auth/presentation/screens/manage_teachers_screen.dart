import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/user_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final UserService _userService = UserService();
  Future<List<dynamic>>? _teachersFuture;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  void _loadTeachers() {
    setState(() {
      _teachersFuture = _userService.getAllUsers().then(
        (users) => users.where((user) => user['role'] == 'teacher').toList()
      );
    });
  }

  Future<void> _showAddTeacherDialog() async {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final loginCodeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة مدرس جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                TextFormField(
                  controller: loginCodeController,
                  decoration: const InputDecoration(labelText: 'كود الدخول'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('إضافة'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _userService.createUser(
                      fullNameController.text,
                      loginCodeController.text,
                      'teacher',
                    );
                    Navigator.of(context).pop();
                    _loadTeachers(); // Refresh the list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المدرسين'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _teachersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مدرسون لعرضهم.'));
          }

          final teachers = snapshot.data!;
          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return ListTile(
                title: Text(teacher['full_name']),
                subtitle: Text('الكود: ${teacher['login_code']}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        tooltip: 'إضافة مدرس',
        child: const Icon(Icons.add),
      ),
    );
  }
}
