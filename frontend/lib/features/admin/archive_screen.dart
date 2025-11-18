import 'package:flutter/material.dart';
import 'package:frontend/features/admin/class_archive_screen.dart';
import 'package:frontend/features/teacher/manage_grades_screen.dart';
import 'package:frontend/features/admin/chat_history_widget.dart';

class ArchiveScreen extends StatelessWidget {
  final Map<String, dynamic> classData;
  const ArchiveScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Archive for ${classData['class_name']}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.video_library), text: 'Recordings'),
              Tab(icon: Icon(Icons.chat), text: 'Chat History'),
              Tab(icon: Icon(Icons.grade), text: 'Grades'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ClassArchiveScreen(classData: classData),
            ChatHistoryWidget(classId: classData['class_id']),
            ManageGradesScreen(classData: classData),
          ],
        ),
      ),
    );
  }
}
