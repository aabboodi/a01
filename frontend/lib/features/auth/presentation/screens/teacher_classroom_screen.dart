import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';

class TeacherClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const TeacherClassroomScreen({super.key, required this.classData});

  @override
  State<TeacherClassroomScreen> createState() => _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState extends State<TeacherClassroomScreen> {
  late ClassroomService _classroomService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isBroadcasting = false;
  String _serverMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the renderer
    await _localRenderer.initialize();

    // Initialize and connect the classroom service
    _classroomService = ClassroomService(onJoinedRoom: (message) {
      if (mounted) setState(() => _serverMessage = message);
    });
    _classroomService.connectAndJoin(widget.classData['class_id']);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _classroomService.dispose();
    super.dispose();
  }

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      // Stop the stream
      _localStream?.getTracks().forEach((track) => track.stop());
      _localRenderer.srcObject = null;
      setState(() => _isBroadcasting = false);
      return;
    }

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });

      _localStream = stream;
      _localRenderer.srcObject = _localStream;

      setState(() => _isBroadcasting = true);

      // TODO: Create a peer connection and send the stream to other participants
    } catch (e) {
      print('Error accessing media devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
        // ... (actions remain the same)
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isBroadcasting
                  ? RTCVideoView(_localRenderer, mirror: true)
                  : const Center(
                      child: Text('البث متوقف', style: TextStyle(color: Colors.white)),
                    ),
            ),
          ),
          // A small bar to show server messages
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Text('حالة الخادم: $_serverMessage'),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  _isBroadcasting ? Icons.videocam_off : Icons.videocam,
                  _isBroadcasting ? 'إيقاف البث' : 'بدء البث',
                  _toggleBroadcast,
                ),
                // ... (other buttons remain non-functional for now)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    // ... (buildControlButton remains the same)
        return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed, iconSize: 30),
        Text(label),
      ],
    );
  }
}
