import 'package:flutter/material.dart';
import 'package:frontend/features/auth/application/services/recording_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ArchiveScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ArchiveScreen({Key? key, required this.classData}) : super(key: key);

  @override
  _ArchiveScreenState createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final RecordingService _recordingService = RecordingService();
  Future<List<dynamic>>? _recordingsFuture;

  @override
  void initState() {
    super.initState();
    _recordingsFuture = _recordingService.getRecordingsForClass(widget.classData['class_id']);
  }

  Future<void> _launchUrl(String filePath) async {
    final Uri url = Uri.parse('http://10.0.2.2:3000/$filePath');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recordings for ${widget.classData['class_name']}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _recordingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recordings available.'));
          }

          final recordings = snapshot.data!;
          return ListView.builder(
            itemCount: recordings.length,
            itemBuilder: (context, index) {
              final recording = recordings[index];
              return ListTile(
                leading: const Icon(Icons.videocam),
                title: Text('Recording from ${recording['start_time']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: recording['file_path'] != null
                      ? () => _launchUrl(recording['file_path'])
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
