import 'package:flutter/material.dart';
import 'package:frontend/core/services/class_service.dart';
import 'package:frontend/core/services/user_service.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final ClassService _classService = ClassService();
  final UserService _userService = UserService();

  List<dynamic> _classes = [];
  List<dynamic> _teachers = [];
  List<dynamic> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classesFuture = _classService.getAllClasses();
      final teachersFuture = _userService.getUsersByRole('teacher');
      final studentsFuture = _userService.getUsersByRole('student');
      final results = await Future.wait([classesFuture, teachersFuture, studentsFuture]);
      setState(() {
        _classes = results[0];
        _teachers = results[1];
        _students = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      await _classService.deleteClass(classId);
      _loadData();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _showAddClassDialog() async {
    final formKey = GlobalKey<FormState>();
    final classNameController = TextEditingController();
    String? selectedTeacherId;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة صف جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: classNameController,
                  decoration: const InputDecoration(labelText: 'اسم الصف'),
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                ),
                DropdownButtonFormField<String>(
                  hint: const Text('اختر مدرسًا'),
                  value: selectedTeacherId,
                  onChanged: (newValue) => setState(() => selectedTeacherId = newValue),
                  items: _teachers.map<DropdownMenuItem<String>>((teacher) {
                    return DropdownMenuItem<String>(
                      value: teacher['user_id'],
                      child: Text(teacher['full_name']),
                    );
                  }).toList(),
                  validator: (v) => v == null ? 'الرجاء اختيار مدرس' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              child: const Text('إضافة'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _classService.createClass(classNameController.text, selectedTeacherId!);
                    Navigator.of(context).pop();
                    _loadData();
                  } catch (e) {
                    _showError(e.toString());
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEnrollStudentsDialog(String classId, List<dynamic> enrolledStudents) async {
    final List<String> selectedStudentIds = enrolledStudents.map<String>((s) => s['user_id']).toList();

    return showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تسجيل الطلاب في الصف'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final isEnrolled = selectedStudentIds.contains(student['user_id']);
                    return CheckboxListTile(
                      title: Text(student['full_name']),
                      value: isEnrolled,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedStudentIds.add(student['user_id']);
                          } else {
                            selectedStudentIds.remove(student['user_id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  child: const Text('حفظ'),
                  onPressed: () async {
                    try {
                      await _classService.enrollStudents(classId, selectedStudentIds);
                      Navigator.of(context).pop();
                      _loadData();
                    } catch (e) {
                      _showError(e.toString());
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الصفوف')),
      body: _buildClassList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        tooltip: 'إضافة صف',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('خطأ: $_error'));
    if (_classes.isEmpty) return const Center(child: Text('لا يوجد صفوف لعرضها.'));

    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final aClass = _classes[index];
        final teacher = _teachers.firstWhere(
          (t) => t['user_id'] == aClass['teacher_id'],
          orElse: () => {'full_name': 'غير معروف'},
        );
        final enrolledStudents = aClass['enrollments']?.map((e) => e['student']).toList() ?? [];

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(aClass['class_name']),
            subtitle: Text('المدرس: ${teacher['full_name']} | الطلاب: ${enrolledStudents.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.blue),
                  onPressed: () => _showEnrollStudentsDialog(aClass['class_id'], enrolledStudents),
                  tooltip: 'تسجيل طلاب',
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
  }
}
