import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart';
import 'package:frontend/features/auth/application/services/recording_service.dart';
import 'package:frontend/features/auth/application/services/grades_service.dart';
import 'package:frontend/features/classroom/presentation/screens/video_player_screen.dart';
import 'package:intl/intl.dart';

class ClassArchiveScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassArchiveScreen({super.key, required this.classData});

  @override
  State<ClassArchiveScreen> createState() => _ClassArchiveScreenState();
}

class _ClassArchiveScreenState extends State<ClassArchiveScreen> {
  final ApiChatService _apiChatService = ApiChatService();
  final RecordingService _recordingService = RecordingService();
  final GradesService _gradesService = GradesService();
  Future<List<dynamic>>? _chatHistoryFuture;
  Future<List<dynamic>>? _recordingsFuture;
  Future<List<dynamic>>? _gradesFuture;

  @override
  void initState() {
    super.initState();
    _chatHistoryFuture = _apiChatService.getChatHistory(widget.classData['class_id']);
    _recordingsFuture = _recordingService.getRecordingsForClass(widget.classData['class_id']);
    _gradesFuture = _gradesService.getGradesForClass(widget.classData['class_id']);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('أرشيف: ${widget.classData['class_name']}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat), text: 'المحادثات'),
              Tab(icon: Icon(Icons.videocam), text: 'التسجيلات'),
              Tab(icon: Icon(Icons.grade), text: 'العلامات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatHistoryView(),
            _buildRecordingsView(),
            _buildGradesView(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryView() {
    return FutureBuilder<List<dynamic>>(
      future: _chatHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد رسائل لعرضها.'));
        }

        final messages = snapshot.data!;
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final author = msg['user']?['full_name'] ?? 'مستخدم محذوف';
            return ListTile(
              title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(msg['message']),
            );
          },
        );
      },
    );
  }

  Widget _buildGradesView() {
    return FutureBuilder<List<dynamic>>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد علامات لعرضها.'));
        }

        final grades = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('اسم الطالب')),
              DataColumn(label: Text('تفاعل')),
              DataColumn(label: Text('واجبات')),
              DataColumn(label: Text('شفهي')),
              DataColumn(label: Text('خطي')),
              DataColumn(label: Text('نهائي')),
            ],
            rows: grades.map((grade) {
              final studentName = grade['student']?['full_name'] ?? 'N/A';
              return DataRow(cells: [
                DataCell(Text(studentName)),
                DataCell(Text(grade['interaction_grade']?.toString() ?? '0')),
                DataCell(Text(grade['homework_grade']?.toString() ?? '0')),
                DataCell(Text(grade['oral_exam_grade']?.toString() ?? '0')),
                DataCell(Text(grade['written_exam_grade']?.toString() ?? '0')),
                DataCell(Text(grade['final_grade']?.toString() ?? '0')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRecordingsView() {
    return FutureBuilder<List<dynamic>>(
      future: _recordingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد تسجيلات لعرضها.'));
        }

        final recordings = snapshot.data!;
        return ListView.builder(
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final rec = recordings[index];
            final startTime = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(rec['start_time']));
            final videoUrl = 'http://10.0.2.2:3000/${rec['file_path']}';

            return ListTile(
              leading: const Icon(Icons.video_library),
              title: Text('تسجيل من: $startTime'),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
