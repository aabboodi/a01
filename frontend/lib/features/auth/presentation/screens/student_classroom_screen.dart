import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package.frontend/features/auth/application/services/classroom_service.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart';
import 'package:frontend/features/classroom/presentation/widgets/whiteboard_widget.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data model for ChatMessage
class ChatMessage {
  final String message;
  final String senderId;
  final bool isLocal;
  final String authorName;

  ChatMessage({
    required this.message,
    required this.senderId,
    required this.isLocal,
    required this.authorName,
  });
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

  // State variables
  String _serverMessage = '';
  bool _requestSent = false;
  bool _isWhiteboardVisible = true;
  String? _userId;

  // Services
  final ApiChatService _apiChatService = ApiChatService();

  // Chat state
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // WebRTC configuration
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
    await _loadUserData();
    _setupClassroomService();
    _loadChatHistory();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      final decodedToken = JwtDecoder.decode(token);
      _userId = decodedToken['userId'];
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _apiChatService.getChatHistory(widget.classData['class_id']);
      final historicalMessages = history.map((msg) => ChatMessage(
        message: msg['message'],
        senderId: msg['user']?['user_id'] ?? 'unknown',
        isLocal: msg['user']?['user_id'] == _userId,
        authorName: msg['user']?['full_name'] ?? 'Unknown User',
      )).toList();

      if (mounted) {
        setState(() {
          _chatMessages.addAll(historicalMessages);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Failed to load chat history: $e");
    }
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
              isLocal: data['user']['user_id'] == _userId,
              authorName: data['user']['full_name'],
            ));
          });
          _scrollToBottom();
        }
      },
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
      onAnswerReceived: (data) {
        // Not typically used by student
      },
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
      onRequestToSpeakReceived: (data) {
        // Student sends, doesn't receive this
      },
      onPermissionToSpeakReceived: (data) {
        print("Permission to speak received!");
        _startAudioBroadcast(data['teacherSocketId']);
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

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && mounted) {
        setState(() {
           _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _peerConnection!.onIceCandidate = (event) {
      if (event.candidate != null) {
        _classroomService.sendIceCandidate(widget.classData['class_id'], {
          'candidate': event.candidate!.candidate,
          'sdpMid': event.candidate!.sdpMid,
          'sdpMLineIndex': event.candidate!.sdpMLineIndex,
        });
      }
    };
  }

  // --- UI Actions ---

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty && _userId != null) {
      _classroomService.sendChatMessage(widget.classData['class_id'], message, userId: _userId!);
      // Message is added via listener to avoid duplication
      _chatController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleRequestToSpeak() {
    _classroomService.sendRequestToSpeak(
      widget.classData['class_id'],
      widget.userData['user_id'].toString(), // Ensure ID is a string
      widget.userData['full_name'],
    );
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب المداخلة بنجاح.')),
    );
  }

  Future<void> _startAudioBroadcast(String teacherSocketId) async {
    if (_peerConnection == null) {
      print("Cannot start audio broadcast without a peer connection.");
      return;
    }

    try {
      // Get audio stream
      MediaStream audioStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

      // Add audio track to the existing connection
      audioStream.getAudioTracks().forEach((track) {
        _peerConnection!.addTrack(track, audioStream);
      });

      // Create a new offer to renegotiate the connection
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1, // Keep existing video stream
      });
      await _peerConnection!.setLocalDescription(offer);

      // Send the offer specifically to the teacher
      _classroomService.sendOffer(widget.classData['class_id'], {'sdp': offer.sdp, 'type': offer.type}, targetId: teacherSocketId);

      print("Audio broadcast started and offer sent to teacher.");

    } catch (e) {
      print("Error starting audio broadcast: $e");
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
      ),
      body: Column(
        children: [
          // Video/Whiteboard View
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  RTCVideoView(_remoteRenderer, mirror: false),
                  // The WhiteboardWidget for the student is "read-only"
                  if (_isWhiteboardVisible)
                    WhiteboardWidget(
                      socket: _classroomService.socket,
                      classId: widget.classData['class_id'],
                      isTeacher: false, // Student cannot draw
                    ),
                ],
              ),
            ),
          ),
          // Chat View
          Expanded(
            flex: 2,
            child: _buildChatView(),
          ),
          // Status and Controls
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Text('حالة الخادم: $_serverMessage'),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              return ListTile(
                title: Text(msg.authorName, style: TextStyle(fontWeight: FontWeight.bold, color: msg.isLocal ? Colors.blue : Colors.black)),
                subtitle: Text(msg.message),
                tileColor: msg.isLocal ? Colors.blue.withOpacity(0.05) : null,
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
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            Icons.pan_tool,
            'طلب مداخلة',
            _requestSent ? null : _handleRequestToSpeak,
          ),
          _buildControlButton(
            _isWhiteboardVisible ? Icons.edit_off : Icons.edit,
            _isWhiteboardVisible ? 'إخفاء السبورة' : 'عرض السبورة',
            () {
              setState(() => _isWhiteboardVisible = !_isWhiteboardVisible);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback? onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 30,
          color: onPressed != null ? Theme.of(context).primaryColor : Colors.grey,
        ),
        Text(label, style: TextStyle(color: onPressed != null ? Colors.black : Colors.grey)),
      ],
    );
  }
}
