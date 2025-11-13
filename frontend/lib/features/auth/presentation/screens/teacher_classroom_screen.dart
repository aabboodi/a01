import 'package:flutter/material.dart';

class TeacherClassroomScreen extends StatelessWidget {
  final Map<String, dynamic> classData;

  const TeacherClassroomScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(classData['class_name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              // TODO: Show list of students
            },
            tooltip: 'قائمة الطلاب',
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              // TODO: Open chat panel
            },
            tooltip: 'المحادثة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content area for video or screen share
          Expanded(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'سيتم عرض الفيديو أو مشاركة الشاشة هنا',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // Control bar at the bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(Icons.videocam, 'بدء/إيقاف', () {}),
                _buildControlButton(Icons.screen_share, 'مشاركة الشاشة', () {}),
                _buildControlButton(Icons.mic_off, 'كتم الصوت', () {}),
                _buildControlButton(Icons.fiber_manual_record, 'تسجيل', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed, iconSize: 30),
        Text(label),
      ],
    );
  }
}
