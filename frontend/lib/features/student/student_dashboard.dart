import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/class_service.dart';
import 'package:frontend/features/student/student_classroom_screen.dart';
import 'package:frontend/core/services/local_db_service.dart';

class StudentDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StudentDashboard({super.key, required this.userData});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ClassService _classService = ClassService();
  final LocalDbService _localDbService = LocalDbService();
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    // Load from cache first
    final cachedClasses = await _localDbService.getCachedClasses();
    if (mounted) {
      setState(() {
        _classes = cachedClasses;
        _isLoading = false; // Show cached data immediately
      });
    }

    // Then fetch from network
    try {
      final networkClasses = await _classService.getClassesForStudent(widget.userData['userId']);
      await _localDbService.cacheClasses(networkClasses);
      if (mounted) {
        setState(() {
          _classes = networkClasses;
        });
      }
    } catch (e) {
      // Handle network error, the user will still see the cached data
      print("Failed to fetch classes from network: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم الطالب: ${widget.userData['loginCode']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(child: Text('أنت غير مسجل في أي فصل دراسي.'))
              : ListView.builder(
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classData = _classes[index];
                    final teacherName = classData['teacher']?['full_name'] ?? 'غير محدد';
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          classData['class_name'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          'المدرس: $teacherName',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: ElevatedButton(
                          child: const Text('دخول الفصل'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => StudentClassroomScreen(
                                  classData: classData,
                                  userData: widget.userData,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
