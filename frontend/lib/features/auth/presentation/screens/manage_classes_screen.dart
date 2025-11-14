import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/auth/application/services/user_service.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final ClassService _classService = ClassService();
  final UserService _userService = UserService();
  Future<List<dynamic>>? _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture = _classService.getAllClasses();
    });
  }

  Future<void> _deleteClass(String classId) async {
    try {
      await _classService.deleteClass(classId);
      _loadClasses(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddClassDialog() async {
    final formKey = GlobalKey<FormState>();
    final classNameController = TextEditingController();
    String? selectedTeacherId;

    // Use the efficient API call
    final teachers = await _userService.getUsersByRole('teacher');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إنشاء صف جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: classNameController,
                  decoration: const InputDecoration(labelText: 'اسم الصف'),
                  validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'اختر مدرسًا'),
                  items: teachers.map<DropdownMenuItem<String>>((teacher) {
                    return DropdownMenuItem<String>(
                      value: teacher['user_id'],
                      child: Text(teacher['full_name']),
                    );
                  }).toList(),
                  onChanged: (value) => selectedTeacherId = value,
                  validator: (value) => value == null ? 'الرجاء اختيار مدرس' : null,
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
              child: const Text('إنشاء'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _classService.createClass(
                      classNameController.text,
                      selectedTeacherId!,
                    );
                    Navigator.of(context).pop();
                    _loadClasses();
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

  Future<void> _showEnrollStudentsDialog(String classId) async {
    final studentCodesController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل طلاب جدد'),
          content: TextField(
            controller: studentCodesController,
            decoration: const InputDecoration(
              labelText: 'أدخل أكواد الطلاب (مفصولة بفاصلة)',
              hintText: 'student01,student02,...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('تسجيل'),
              onPressed: () async {
                final codes = studentCodesController.text.split(',').map((e) => e.trim()).toList();
                List<String> studentIds = [];
                try {
                  for (String code in codes) {
                    if (code.isNotEmpty) {
                      final student = await _userService.findUserByLoginCode(code);
                      studentIds.add(student['user_id']);
                    }
                  }
                  await _classService.enrollStudents(classId, studentIds);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الطلاب بنجاح!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
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
        title: const Text('إدارة الصفوف'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد صفوف لعرضها.'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final aClass = classes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(aClass['class_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المدرس: ${aClass['teacher']['full_name']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.blue),
                        onPressed: () => _showEnrollStudentsDialog(aClass['class_id']),
                        tooltip: 'إدارة الطلاب',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteClass(aClass['class_id']),
                        tooltip: 'حذف الصف',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        tooltip: 'إنشاء صف',
        child: const Icon(Icons.add),
      ),
    );
  }
}
