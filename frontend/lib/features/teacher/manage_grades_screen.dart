import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/grades_service.dart';
import 'package:frontend/features/auth/application/services/user_service.dart';

class ManageGradesScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ManageGradesScreen({super.key, required this.classData});

  @override
  State<ManageGradesScreen> createState() => _ManageGradesScreenState();
}

class _ManageGradesScreenState extends State<ManageGradesScreen> {
  final GradesService _gradesService = GradesService();
  final UserService _userService = UserService();

  List<dynamic> _students = [];
  Map<String, dynamic> _grades = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final students = await _userService.getUsersByClass(widget.classData['class_id']);
      final grades = await _gradesService.getGradesForClass(widget.classData['class_id']);

      final gradesMap = <String, dynamic>{for (var g in grades) g['student']['user_id']: g};

      setState(() {
        _students = students;
        _grades = gradesMap;
        _isLoading = false;
      });
    } catch (e) {
      print("Failed to fetch data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Grades for ${widget.classData['class_name']}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('Interaction')),
                  DataColumn(label: Text('Homework')),
                  DataColumn(label: Text('Oral Exam')),
                  DataColumn(label: Text('Written Exam')),
                  DataColumn(label: Text('Final Grade')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _students.map((student) {
                  final studentId = student['user_id'];
                  final grade = _grades[studentId];
                  return DataRow(cells: [
                    DataCell(Text(student['full_name'])),
                    DataCell(Text(grade?['interaction_grade']?.toString() ?? '0')),
                    DataCell(Text(grade?['homework_grade']?.toString() ?? '0')),
                    DataCell(Text(grade?['oral_exam_grade']?.toString() ?? '0')),
                    DataCell(Text(grade?['written_exam_grade']?.toString() ?? '0')),
                    DataCell(Text(grade?['final_grade']?.toString() ?? '0')),
                    DataCell(IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditGradeDialog(context, student, grade);
                      },
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  void _showEditGradeDialog(BuildContext context, dynamic student, dynamic currentGrade) {
    final interactionController = TextEditingController(text: currentGrade?['interaction_grade']?.toString() ?? '0');
    final homeworkController = TextEditingController(text: currentGrade?['homework_grade']?.toString() ?? '0');
    final oralExamController = TextEditingController(text: currentGrade?['oral_exam_grade']?.toString() ?? '0');
    final writtenExamController = TextEditingController(text: currentGrade?['written_exam_grade']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Grades for ${student['full_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: interactionController, decoration: const InputDecoration(labelText: 'Interaction (Max 7)'), keyboardType: TextInputType.number),
                TextField(controller: homeworkController, decoration: const InputDecoration(labelText: 'Homework (Max 7)'), keyboardType: TextInputType.number),
                TextField(controller: oralExamController, decoration: const InputDecoration(labelText: 'Oral Exam (Max 60)'), keyboardType: TextInputType.number),
                TextField(controller: writtenExamController, decoration: const InputDecoration(labelText: 'Written Exam (Max 7)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                try {
                  final gradeData = {
                    'studentId': student['user_id'],
                    'classId': widget.classData['class_id'],
                    'interaction_grade': double.parse(interactionController.text),
                    'homework_grade': double.parse(homeworkController.text),
                    'oral_exam_grade': double.parse(oralExamController.text),
                    'written_exam_grade': double.parse(writtenExamController.text),
                  };
                  await _gradesService.upsertGrade(gradeData);
                  Navigator.pop(context);
                  _fetchData(); // Refresh data
                } catch (e) {
                  // Show error
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
