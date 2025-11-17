import 'package:flutter/material.dart';
import 'package:frontend/core/services/chat_service.dart';
import 'package:frontend/core/services/mediasoup_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class TeacherClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const TeacherClassroomScreen({super.key, required this.classData});

  @override
  State<TeacherClassroomScreen> createState() => _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState extends State<TeacherClassroomScreen> {
  final ChatService _chatService = ChatService();
  final MediasoupService _mediasoupService = MediasoupService();
  final TextEditingController _chatController = TextEditingController();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  List<dynamic> _chatMessages = [];
  List<dynamic> _attendees = [];
  bool _isLoadingChat = true;
  MediaStream? _localStream;
  Producer? _videoProducer;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();
    _loadChatHistory();
    _initSocket();
    _connectMediasoup();
  }

  Future<void> _connectMediasoup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      await _mediasoupService.connect(widget.classData['class_id'], token!);
    } catch (e) { /* Handle error */ }
  }

  Future<void> _startBroadcast() async {
    final stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    setState(() {
      _localStream = stream;
      _localRenderer.srcObject = stream;
    });
    final transport = await _mediasoupService.createSendTransport(widget.classData['class_id']);
    final videoTrack = stream.getVideoTracks().first;
    _videoProducer = await transport.produce(track: videoTrack);
  }

  void _stopBroadcast() {
    _videoProducer?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    setState(() {
      _localStream = null;
      _localRenderer.srcObject = null;
    });
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoadingChat = true);
    try {
      final history = await _chatService.getChatHistory(widget.classData['class_id']);
      setState(() {
        _chatMessages = history;
        _isLoadingChat = false;
      });
    } catch (e) { /* Handle error */ }
  }

  void _initSocket() {
    _socket = IO.io('http://10.0.2.2:3000/classroom', <String, dynamic>{'transports': ['websocket'], 'autoConnect': false});
    _socket.connect();
    _socket.on('connect', (_) => _socket.emit('join-room', {'classId': widget.classData['class_id']}));
    _socket.on('chat-message', (data) => setState(() => _chatMessages.add(data)));
  }

  void _sendMessage() {
    if (_chatController.text.isNotEmpty) {
      _socket.emit('chat-message', {'classId': widget.classData['class_id'], 'message': _chatController.text});
      _chatController.clear();
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _mediasoupService.dispose();
    _socket.dispose();
    _chatController.dispose();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
        actions: [
          IconButton(
            icon: Icon(_localStream == null ? Icons.videocam_off : Icons.videocam, color: _localStream == null ? Colors.red : Colors.green),
            onPressed: _localStream == null ? _startBroadcast : _stopBroadcast,
            tooltip: _localStream == null ? 'بدء البث' : 'إيقاف البث',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _localStream != null
                  ? RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
                  : const Center(child: Text('البث متوقف', style: TextStyle(color: Colors.white))),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildChatAndAttendees(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatAndAttendees() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'المحادثة'), Tab(text: 'الحضور')]),
          Expanded(
            child: TabBarView(children: [_buildChat(), _buildAttendeesList()]),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingChat
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    return ListTile(
                      title: Text(msg['author_name'] ?? 'System'),
                      subtitle: Text(msg['message']),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: 'اكتب رسالة...'))),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesList() {
    return ListView.builder(
      itemCount: _attendees.length,
      itemBuilder: (context, index) => ListTile(title: Text(_attendees[index]['full_name'])),
    );
  }
}
