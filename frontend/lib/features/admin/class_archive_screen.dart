import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/recording_service.dart';
import 'package:frontend/features/classroom/presentation/screens/video_player_screen.dart';
import 'package:intl/intl.dart';

class ClassArchiveScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassArchiveScreen({super.key, required this.classData});

  @override
  State<ClassArchiveScreen> createState() => _ClassArchiveScreenState();
}

class _ClassArchiveScreenState extends State<ClassArchiveScreen> {
  final RecordingService _recordingService = RecordingService();
  Future<List<dynamic>>? _recordingsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  void _loadRecordings() {
    setState(() {
      _recordingsFuture = _recordingService.getRecordingsForClass(widget.classData['class_id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _recordingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final recordings = snapshot.data ?? [];
          if (recordings.isEmpty) {
            return const Center(child: Text('No recordings found.'));
          }
          return ListView.builder(
            itemCount: recordings.length,
            itemBuilder: (context, index) {
              final recording = recordings[index];
              final startTime = DateTime.parse(recording['start_time']);
              return ListTile(
                title: Text('Recording from ${DateFormat.yMd().add_jm().format(startTime)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          videoUrl: 'http://10.0.2.2:3000/${recording['file_path']}',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
