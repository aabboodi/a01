import 'package:flutter/material.dart';
import 'package:frontend/core/services/chat_service.dart';
import 'package:frontend/core/services/mediasoup_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';

class StudentClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const StudentClassroomScreen({super.key, required this.classData});

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {
  final ChatService _chatService = ChatService();
  final MediasoupService _mediasoupService = MediasoupService();
  final TextEditingController _chatController = TextEditingController();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  List<dynamic> _chatMessages = [];
  bool _isLoadingChat = true;
  MediaStream? _remoteStream;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _remoteRenderer.initialize();
    _loadChatHistory();
    _initSocket();
    await _connectMediasoup();
  }

  Future<void> _connectMediasoup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      await _mediasoupService.connect(widget.classData['class_id'], token!);
    } catch (e) { /* Handle error */ }
  }

  Future<void> _subscribe(String producerId) async {
    try {
      final transport = await _mediasoupService.createRecvTransport(widget.classData['class_id']);
      final consumer = await _mediasoupService.consume(transport, producerId, _mediasoupService.rtpCapabilities);
      final stream = MediaStream([consumer.track], 'remote');
      setState(() {
        _remoteStream = stream;
        _remoteRenderer.srcObject = stream;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _initSocket() {
     _socket = IO.io('http://10.0.2.2:3000/classroom', <String, dynamic>{'transports': ['websocket'], 'autoConnect': false});
    _socket.connect();
    _socket.on('connect', (_) {
      _socket.emit('join-room', {'classId': widget.classData['class_id']});
      _socket.emit('get-producers', {'classId': widget.classData['class_id']});
    });
    _socket.on('chat-message', (data) => setState(() => _chatMessages.add(data)));
    _socket.on('new-producer', (data) => _subscribe(data['producerId']));
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

  void _sendMessage() {
    if (_chatController.text.isNotEmpty) {
      _socket.emit('chat-message', {'classId': widget.classData['class_id'], 'message': _chatController.text});
      _chatController.clear();
    }
  }

  void _requestToSpeak() {
    _socket.emit('request-to-speak', {'classId': widget.classData['class_id']});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك للتحدث.'), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _mediasoupService.dispose();
    _remoteStream?.dispose();
    _socket.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.classData['class_name'])),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _remoteStream != null
                  ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
                  : const Center(child: Text('في انتظار بث المدرس...', style: TextStyle(color: Colors.white))),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildChatAndActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatAndActions() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingChat
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    return ListTile(title: Text(msg['author_name'] ?? 'System'), subtitle: Text(msg['message']));
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: 'اكتب رسالة...'))),
                  IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: _requestToSpeak, icon: const Icon(Icons.pan_tool), label: const Text('طلب التحدث')),
            ],
          ),
        ),
      ],
    );
  }
}
