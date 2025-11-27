import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/user_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students = await _userService.getUsersByRole('student');
      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student['full_name'].toString().toLowerCase();
        final code = student['login_code'].toString().toLowerCase();
        final phone = student['phone_number']?.toString().toLowerCase() ?? '';
        return name.contains(query) || code.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteStudent(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(userId);
        _loadStudents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddStudentDialog() async {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'full_name': TextEditingController(),
      'login_code': TextEditingController(),
      'phone_number': TextEditingController(),
      'age': TextEditingController(),
      'education_level': TextEditingController(),
      'address': TextEditingController(),
      'father_phone_number': TextEditingController(),
    };

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة طالب جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: controllers['full_name'],
                    decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                  ),
                  TextFormField(
                    controller: controllers['login_code'],
                    decoration: const InputDecoration(labelText: 'كود الدخول'),
                    validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                  ),
                  TextFormField(
                    controller: controllers['phone_number'],
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  TextFormField(
                    controller: controllers['age'],
                    decoration: const InputDecoration(labelText: 'العمر'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: controllers['education_level'],
                    decoration: const InputDecoration(labelText: 'المستوى التعليمي'),
                  ),
                  TextFormField(
                    controller: controllers['address'],
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextFormField(
                    controller: controllers['father_phone_number'],
                    decoration: const InputDecoration(labelText: 'رقم هاتف ولي الأمر'),
                  ),
                ],
              ),
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
                    final userData = {
                      'full_name': controllers['full_name']!.text,
                      'login_code': controllers['login_code']!.text,
                      'phone_number': controllers['phone_number']!.text,
                      'age': int.tryParse(controllers['age']!.text),
                      'education_level': controllers['education_level']!.text,
                      'address': controllers['address']!.text,
                      'father_phone_number': controllers['father_phone_number']!.text,
                      'role': 'student',
                    };
                    // Remove null or empty values
                    userData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

                    await _userService.createUser(userData);
                    Navigator.of(context).pop();
                    _loadStudents();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلاب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث بالاسم, الكود, أو الهاتف',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _buildStudentTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        tooltip: 'إضافة طالب',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('خطأ: $_error'));
    }
    if (_filteredStudents.isEmpty) {
      return const Center(child: Text('لا يوجد طلاب لعرضهم.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('الاسم الكامل')),
            DataColumn(label: Text('كود الدخول')),
            DataColumn(label: Text('الهاتف')),
            DataColumn(label: Text('العمر')),
            DataColumn(label: Text('المستوى التعليمي')),
            DataColumn(label: Text('تاريخ الإنشاء')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: _filteredStudents.map((student) {
            final createdAt = student['created_at'] != null
                ? DateTime.parse(student['created_at'])
                : null;
            final isNew = createdAt != null && DateTime.now().difference(createdAt).inDays <= 7;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    student['full_name'],
                    style: TextStyle(color: isNew ? Colors.green : Colors.black),
                  ),
                ),
                DataCell(Text(student['login_code'] ?? 'N/A')),
                DataCell(Text(student['phone_number'] ?? 'N/A')),
                DataCell(Text(student['age']?.toString() ?? 'N/A')),
                DataCell(Text(student['education_level'] ?? 'N/A')),
                DataCell(Text(createdAt != null ? '${createdAt.year}-${createdAt.month}-${createdAt.day}' : 'N/A')),
                DataCell(IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStudent(student['user_id'], student['full_name']),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
