import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';

// Simple class to hold message data
class ChatMessage {
  final String message;
  final String senderId;
  final bool isLocal;

  ChatMessage({required this.message, required this.senderId, required this.isLocal});
}

class StudentClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Map<String, dynamic> userData;

  const StudentClassroomScreen({
    super.key,
    required this.classData,
    required this.userData,
  });

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {
  late ClassroomService _classroomService;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  String _serverMessage = '';
  bool _requestSent = false;

  // Chat state
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _remoteRenderer.initialize();
    _setupClassroomService();
  }

  void _setupClassroomService() {
    _classroomService = ClassroomService(
      onJoinedRoom: (message) {
        if (mounted) setState(() => _serverMessage = message);
      },
      onChatMessageReceived: (data) {
        if (mounted) {
          setState(() {
            _chatMessages.add(ChatMessage(
              message: data['message'],
              senderId: data['senderId'],
              isLocal: false,
            ));
          });
          _scrollToBottom();
        }
      },
      // ... (WebRTC callbacks remain the same)
          onOfferReceived: (data) async {
        print("Offer received");
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
        );
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _classroomService.sendAnswer(widget.classData['class_id'], {'sdp': answer.sdp, 'type': answer.type});
      },
      onAnswerReceived: (data) {},
      onIceCandidateReceived: (data) async {
        if (_peerConnection != null) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        }
      },
    );
    _classroomService.connectAndJoin(widget.classData['class_id']);
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _classroomService.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      _classroomService.sendChatMessage(widget.classData['class_id'], message);
      setState(() {
        _chatMessages.add(ChatMessage(message: message, senderId: 'me', isLocal: true));
      });
      _chatController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  void _handleRequestToSpeak() {
    _classroomService.sendRequestToSpeak(
      widget.classData['class_id'],
      widget.userData['user_id'],
      widget.userData['full_name'],
    );
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب المداخلة بنجاح.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
      ),
      body: Column(
        children: [
          // Video View
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: RTCVideoView(_remoteRenderer, mirror: true),
            ),
          ),
          // Chat View
          Expanded(
            flex: 2, // Give chat a bit more space on student's screen
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      return ListTile(
                        title: Text(msg.message),
                        subtitle: Text(msg.isLocal ? 'أنا' : 'مدرس'),
                        tileColor: msg.isLocal ? Colors.blue.withOpacity(0.1) : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.pan_tool,
                        color: _requestSent ? Colors.grey : Colors.blue,
                      ),
                      onPressed: _requestSent ? null : _handleRequestToSpeak,
                      iconSize: 30,
                    ),
                    const Text('طلب مداخلة'),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
