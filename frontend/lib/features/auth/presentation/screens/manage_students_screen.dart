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
      // Use the efficient API call
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

  Future<void> _deleteStudent(String userId) async {
    try {
      await _userService.deleteUser(userId);
      _loadStudents(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddStudentDialog() async {
    // Dialog logic remains the same as it is already well-implemented
        final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final loginCodeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة طالب جديد'),
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
                      'student',
                    );
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
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الاسم الثلاثي')),
          DataColumn(label: Text('الكود')),
          DataColumn(label: Text('رقم الهاتف')),
          DataColumn(label: Text('إجراء')),
        ],
        rows: _filteredStudents.map((student) {
          return DataRow(cells: [
            DataCell(Text(student['full_name'])),
            DataCell(Text(student['login_code'])),
            DataCell(Text(student['phone_number'] ?? 'N/A')),
            DataCell(IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteStudent(student['user_id']),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
