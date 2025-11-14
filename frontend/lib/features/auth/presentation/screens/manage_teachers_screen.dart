import 'package.flutter/material.dart';
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
      _teachersFuture = _userService.getUsersByRole('teacher');
    });
  }

  Future<void> _deleteTeacher(String userId) async {
    try {
      await _userService.deleteUser(userId);
      _loadTeachers(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddTeacherDialog() async {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final loginCodeController = TextEditingController();
    // Simplified CreateUserDto for the dialog
    final Map<String, dynamic> newUser = {
      'full_name': '',
      'login_code': '',
      'role': 'teacher'
    };


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
                  onSaved: (value) => newUser['full_name'] = value!,
                ),
                TextFormField(
                  controller: loginCodeController,
                  decoration: const InputDecoration(labelText: 'كود الدخول'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                  onSaved: (value) => newUser['login_code'] = value!,
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
                  formKey.currentState!.save();
                  try {
                    await _userService.createUser(
                      newUser['full_name'],
                      newUser['login_code'],
                      newUser['role'],
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTeacher(teacher['user_id']),
                ),
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
