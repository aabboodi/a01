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

  Future<void> _deleteClass(String classId, String className) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete $className?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _classService.deleteClass(classId);
        _loadClasses();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showAddClassDialog() {
    final nameController = TextEditingController();
    String? selectedTeacherId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Class Name')),
              FutureBuilder<List<dynamic>>(
                future: _userService.getUsersByRole('teacher'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    hint: const Text('Select Teacher'),
                    onChanged: (value) => selectedTeacherId = value,
                    items:
                        snapshot.data!.map<DropdownMenuItem<String>>((teacher) {
                      return DropdownMenuItem<String>(
                        value: teacher['user_id'],
                        child: Text(teacher['full_name']),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    selectedTeacherId != null) {
                  await _classService.createClass(
                      nameController.text, selectedTeacherId!);
                  Navigator.pop(context);
                  _loadClasses();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEnrollDialog(String classId) {
    showDialog(
      context: context,
      builder: (context) {
        return EnrollStudentDialog(
          classId: classId,
          userService: _userService,
          classService: _classService,
          onEnrollmentComplete: _loadClasses,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classes')),
      body: FutureBuilder<List<dynamic>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final classes = snapshot.data ?? [];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('اسم الصف')),
                DataColumn(label: Text('المدرس')),
                DataColumn(label: Text('إجراءات')),
              ],
              rows: classes.map((classData) {
                return DataRow(cells: [
                  DataCell(Text(classData['class_name'])),
                  DataCell(Text(classData['teacher']?['full_name'] ?? 'N/A')),
                  DataCell(Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () =>
                              _showEnrollDialog(classData['class_id'])),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteClass(
                              classData['class_id'], classData['class_name'])),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EnrollStudentDialog extends StatefulWidget {
  final String classId;
  final UserService userService;
  final ClassService classService;
  final VoidCallback onEnrollmentComplete;

  const EnrollStudentDialog({
    super.key,
    required this.classId,
    required this.userService,
    required this.classService,
    required this.onEnrollmentComplete,
  });

  @override
  State<EnrollStudentDialog> createState() => _EnrollStudentDialogState();
}

class _EnrollStudentDialogState extends State<EnrollStudentDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final allStudents = await widget.userService.getUsersByRole('student');
      final enrolledStudents =
          await widget.classService.getEnrolledStudents(widget.classId);
      final enrolledIds =
          enrolledStudents.map((s) => s['user_id'] as String).toList();
      setState(() {
        _allStudents = allStudents;
        _filteredStudents = allStudents;
        _selectedStudentIds = enrolledIds;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student['full_name'].toString().toLowerCase();
        final code = student['login_code'].toString().toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enroll Students'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or code',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final isSelected =
                            _selectedStudentIds.contains(student['user_id']);
                        return CheckboxListTile(
                          title: Text(student['full_name']),
                          subtitle: Text(student['login_code']),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedStudentIds.add(student['user_id']);
                              } else {
                                _selectedStudentIds.remove(student['user_id']);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            try {
              await widget.classService
                  .enrollStudents(widget.classId, _selectedStudentIds);
              Navigator.pop(context);
              widget.onEnrollmentComplete();
            } catch (e) {
              // Handle error
            }
          },
          child: const Text('Enroll'),
        ),
      ],
    );
  }
}
