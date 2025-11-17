import 'package:flutter/material.dart';
import 'package:frontend/core/services/user_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final UserService _userService = UserService();
  List<dynamic> _teachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final teachers = await _userService.getUsersByRole('teacher');
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
                    _loadTeachers();
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
      body: _buildTeacherTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        tooltip: 'إضافة مدرس',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTeacherTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('خطأ: $_error'));
    }
    if (_teachers.isEmpty) {
      return const Center(child: Text('لا يوجد مدرسين لعرضهم.'));
    }

    return DataTable(
      columns: const [
        DataColumn(label: Text('الاسم الكامل')),
        DataColumn(label: Text('كود الدخول')),
        DataColumn(label: Text('إجراء')),
      ],
      rows: _teachers.map((teacher) {
        return DataRow(cells: [
          DataCell(Text(teacher['full_name'])),
          DataCell(Text(teacher['login_code'])),
          DataCell(IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteTeacher(teacher['user_id']),
          )),
        ]);
      }).toList(),
    );
  }
}
