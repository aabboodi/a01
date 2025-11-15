import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart'; // Import chat service
import 'package:frontend/features/auth/application/services/user_service.dart';
import 'package.frontend/features/auth/application/services/recording_service.dart';
import 'package.frontend/features/classroom/presentation/widgets/whiteboard_widget.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // To decode JWT
import 'package:shared_preferences/shared_preferences.dart'; // To get token
import 'package:url_launcher/url_launcher.dart';
import 'package.frontend/features/auth/application/services/user_service.dart';
import 'package.frontend/features/auth/application/services/recording_service.dart';
import 'package.frontend/features/classroom/presentation/widgets/whiteboard_widget.dart';
import 'package:frontend/features/classroom/presentation/widgets/whiteboard_widget.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // To decode JWT
import 'package:shared_preferences/shared_preferences.dart'; // To get token

// Data models for chat and speak requests
class ChatMessage {
  final String message;
  final String senderId;
  final bool isLocal;
  final String authorName;
  final bool isSystemMessage;
  final String? recordingUrl;

  ChatMessage({
    required this.message,
    required this.senderId,
    required this.isLocal,
    required this.authorName,
    this.isSystemMessage = false,
    this.recordingUrl,
  });
}

class SpeakRequest {
  final String studentId;
  final String studentName;
  final String socketId;

  SpeakRequest({required this.studentId, required this.studentName, required this.socketId});
}

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
  RTCPeerConnection? _peerConnection;

  // Connections for students who are allowed to speak
  final Map<String, RTCPeerConnection> _studentConnections = {};
  final Map<String, RTCVideoRenderer> _studentRenderers = {};

  // State variables
  bool _isBroadcasting = false;
  bool _isScreenSharing = false;
  bool _isWhiteboardActive = false; // New state for the whiteboard
  String _serverMessage = '';
  String? _userId;
  String? _userName;

  // Timer state
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  // Services
  final ApiChatService _apiChatService = ApiChatService();
  final UserService _apiUserService = UserService();
  final RecordingService _recordingService = RecordingService();


  // Services
  final ApiChatService _apiChatService = ApiChatService();
  final UserService _apiUserService = UserService();
  final RecordingService _recordingService = RecordingService();

  // Recording state
  bool _isRecording = false;
  String? _currentRecordingId;
  MediaRecorder? _mediaRecorder;
  String? _recordedFilePath;

  // Services
  final ApiChatService _apiChatService = ApiChatService();

  // Chat and Speak Requests state
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SpeakRequest> _speakRequests = [];

  // Attendance state
  final Set<String> _presentStudentIds = {};
  List<dynamic> _allStudents = []; // Will be fetched

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
    await _localRenderer.initialize();
    await _loadUserData();
    _setupClassroomService();
    _loadChatHistory();
    _fetchAllStudents();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      final decodedToken = JwtDecoder.decode(token);
      _userId = decodedToken['userId'];
      _userName = decodedToken['loginCode']; // Assuming loginCode is the name for now
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _apiChatService.getChatHistory(widget.classData['class_id']);
      final historicalMessages = history.map((msg) {
        final isSystem = msg['user']?['role'] == 'admin';
        final url = isSystem ? _extractUrl(msg['message']) : null;
        return ChatMessage(
          message: msg['message'],
          senderId: msg['user']?['user_id'] ?? 'system',
          isLocal: msg['user']?['user_id'] == _userId,
          authorName: isSystem ? 'System' : (msg['user']?['full_name'] ?? 'Unknown'),
          isSystemMessage: isSystem,
          recordingUrl: url,
        );
      }).toList();
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
          final isSystem = data['user']?['role'] == 'admin';
          final url = isSystem ? _extractUrl(data['message']) : null;
          setState(() {
            _chatMessages.add(ChatMessage(
              message: data['message'],
              senderId: data['senderId'],
              isLocal: data['user']['user_id'] == _userId,
              authorName: isSystem ? 'System' : data['user']['full_name'],
              isSystemMessage: isSystem,
              recordingUrl: url,
              authorName: data['user']['full_name'],
            ));
          });
          _scrollToBottom();
        }
      },
      onRequestToSpeakReceived: (data) {
        if (mounted) {
          setState(() {
            if (!_speakRequests.any((req) => req.studentId == data['studentId'])) {
              _speakRequests.add(SpeakRequest(
                studentId: data['studentId'],
                studentName: data['studentName'],
                socketId: data['socketId'],
              ));
            }
          });
        }
      },
      onAnswerReceived: (data) async {
        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
          );
        }
      },
      onIceCandidateReceived: (data) async {
        // This could be from the main broadcast connection or a student connection
        final connection = _studentConnections[data['senderId']] ?? _peerConnection;
        if (connection != null) {
          await connection.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        }
      },
      onOfferReceived: (data) async {
        // This offer comes from a student who was granted permission to speak
        final studentSocketId = data['senderId'];
        print("Offer received from student $studentSocketId");

        // Create a new peer connection for this student
        final studentConnection = await createPeerConnection(_iceServers, {});

        studentConnection.onTrack = (event) {
          if (event.track.kind == 'audio' && mounted) {
            print("Audio track received from student $studentSocketId");
            // Audio is now only between teacher and student, no relay needed.
          }
        };

        await studentConnection.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
        );

        RTCSessionDescription answer = await studentConnection.createAnswer();
        await studentConnection.setLocalDescription(answer);

        _classroomService.sendAnswer(widget.classData['class_id'], {'sdp': answer.sdp, 'type': answer.type}, targetId: studentSocketId);

        setState(() {
          _studentConnections[studentSocketId] = studentConnection;
        });
      },
      onPermissionToSpeakReceived: (data) {
        // Teacher does not receive this event
      },
      onUserJoined: (data) {
        if (mounted) {
          setState(() {
            _presentStudentIds.add(data['userId']);
          });
        }
      },
      onUserLeft: (data) {
        if (mounted) {
          setState(() {
            _presentStudentIds.remove(data['userId']);
          });
        }
      },
      onCurrentAttendanceReceived: (data) {
        if (mounted) {
          setState(() {
            _presentStudentIds.clear();
            _presentStudentIds.addAll(List<String>.from(data));
          });
        }
      },
    );
    _classroomService.connectAndJoin(
      widget.classData['class_id'],
      _userId!,
      _userName!,
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _studentConnections.forEach((key, value) => value.close());
    _studentRenderers.forEach((key, value) => value.dispose());
    _mediaRecorder?.dispose();
    _classroomService.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- UI Actions ---

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty && _userId != null) {
      _classroomService.sendChatMessage(widget.classData['class_id'], message, userId: _userId!);
      // The message will be added via the 'onChatMessageReceived' listener to avoid duplication
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

  void _showSpeakRequests() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _speakRequests.length,
          itemBuilder: (context, index) {
            final request = _speakRequests[index];
            return ListTile(
              title: Text(request.studentName),
              trailing: ElevatedButton(
                child: const Text('سماح'),
                onPressed: () {
                  _classroomService.allowToSpeak(request.socketId);
                  // Remove the request from the list after allowing
                  setState(() {
                    _speakRequests.removeWhere((r) => r.socketId == request.socketId);
                  });
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- Timer Controls ---

  void _startTimer() {
    _elapsedTime = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // --- Recording Controls ---

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      if (_mediaRecorder != null && _currentRecordingId != null) {
        try {
          final path = await _mediaRecorder!.stop();
          await _recordingService.stopRecording(_currentRecordingId!);

          setState(() {
            _isRecording = false;
            _recordedFilePath = path;
          });

          // Upload the file
          await _recordingService.uploadRecording(_currentRecordingId!, path);

      if (_currentRecordingId != null) {
        try {
          await _recordingService.stopRecording(_currentRecordingId!);
          setState(() {
            _isRecording = false;
            _currentRecordingId = null;
          });
        } catch (e) {
          print("Failed to stop recording: $e");
        }
      }
    } else {
      // Start recording
      if (_localStream != null) {
        try {
          final recording = await _recordingService.startRecording(widget.classData['class_id']);
          _mediaRecorder = MediaRecorder();
          await _mediaRecorder!.start(_localStream!);

          setState(() {
            _isRecording = true;
            _currentRecordingId = recording['recording_id'];
          });
        } catch (e) {
          print("Failed to start recording: $e");
        }
      }
    }
  }

  // --- Data Fetching ---

  Future<void> _fetchAllStudents() async {
    try {
      // Assuming you have a method in your service to get students by class.
      // This might need to be created.
      final students = await _apiUserService.getUsersByClass(widget.classData['class_id']);
      if (mounted) {
        setState(() {
          _allStudents = students;
        });
      }
    } catch (e) {
      print("Failed to fetch students for class: $e");
    }
  }

  // --- UI Actions ---

  void _showAttendance() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _allStudents.length,
          itemBuilder: (context, index) {
            final student = _allStudents[index];
            final isPresent = _presentStudentIds.contains(student['user_id']);
            return ListTile(
              title: Text(student['full_name']),
              trailing: Icon(
                Icons.circle,
                color: isPresent ? Colors.green : Colors.red,
                size: 16,
              ),
            );
          },
        );
      },
    );
  }

    }
  }

  // --- Data Fetching ---

  Future<void> _fetchAllStudents() async {
    try {
      // Assuming you have a method in your service to get students by class.
      // This might need to be created.
      final students = await _apiUserService.getUsersByClass(widget.classData['class_id']);
      if (mounted) {
        setState(() {
          _allStudents = students;
        });
      }
    } catch (e) {
      print("Failed to fetch students for class: $e");
    }
  }

  // --- UI Actions ---

  void _showAttendance() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _allStudents.length,
          itemBuilder: (context, index) {
            final student = _allStudents[index];
            final isPresent = _presentStudentIds.contains(student['user_id']);
            return ListTile(
              title: Text(student['full_name']),
              trailing: Icon(
                Icons.circle,
                color: isPresent ? Colors.green : Colors.red,
                size: 16,
              ),
            );
          },
        );
      },
    );
  }

      try {
        final recording = await _recordingService.startRecording(widget.classData['class_id']);
        setState(() {
          _isRecording = true;
          _currentRecordingId = recording['recording_id'];
        });
      } catch (e) {
        print("Failed to start recording: $e");
      }
    }
  }

  // --- Data Fetching ---

  Future<void> _fetchAllStudents() async {
    try {
      // Assuming you have a method in your service to get students by class.
      // This might need to be created.
      final students = await _apiUserService.getUsersByClass(widget.classData['class_id']);
      if (mounted) {
        setState(() {
          _allStudents = students;
        });
      }
    } catch (e) {
      print("Failed to fetch students for class: $e");
    }
  }

  // --- UI Actions ---

  void _showAttendance() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _allStudents.length,
          itemBuilder: (context, index) {
            final student = _allStudents[index];
            final isPresent = _presentStudentIds.contains(student['user_id']);
            return ListTile(
              title: Text(student['full_name']),
              trailing: Icon(
                Icons.circle,
                color: isPresent ? Colors.green : Colors.red,
                size: 16,
              ),
            );
          },
        );
      },
    );
  }

  // --- Broadcasting and Media Controls ---

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      await _stopBroadcast();
    } else {
      await _startBroadcast();
    }
  }

  // --- Broadcasting and Media Controls ---

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      await _stopBroadcast();
    } else {
      await _startBroadcast();
    }
  }

  Future<void> _startBroadcast() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
      _localRenderer.srcObject = _localStream;

      await _createPeerConnection();

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _classroomService.sendOffer(widget.classData['class_id'], {'sdp': offer.sdp, 'type': offer.type});

      setState(() {
        _isBroadcasting = true;
        _startTimer();
      });
    } catch (e) {
      print('Error starting broadcast: $e');
    }
  }

  Future<void> _stopBroadcast() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _peerConnection?.close();
      _peerConnection = null;
      _localRenderer.srcObject = null;
      setState(() {
        _isBroadcasting = false;
        _isScreenSharing = false;
        _isWhiteboardActive = false;
        _stopTimer();
      });
    } catch (e) {
      print('Error stopping broadcast: $e');
    }
  }

  Future<void> _toggleScreenShare() async {
    if (!_isBroadcasting) return;

    // Turn off whiteboard if active, as they conflict for screen space
    if (_isWhiteboardActive) {
      setState(() => _isWhiteboardActive = false);
    }

    await _switchMediaStream(screenSharing: !_isScreenSharing);
  }


    // Turn off whiteboard if active, as they conflict for screen space
    if (_isWhiteboardActive) {
      setState(() => _isWhiteboardActive = false);
    }

    await _switchMediaStream(screenSharing: !_isScreenSharing);
  }

  void _toggleWhiteboard() {
    if (!_isBroadcasting) return;


    await _switchMediaStream(screenSharing: !_isScreenSharing);
  }

  void _toggleWhiteboard() {
    if (!_isBroadcasting) return;

    // Turn off screen sharing if active
    if (_isScreenSharing) {
       _switchMediaStream(screenSharing: false);
    }

    setState(() => _isWhiteboardActive = !_isWhiteboardActive);
  }

  Future<void> _switchMediaStream({required bool screenSharing}) async {
    if (_peerConnection == null) return;

    _localStream?.getTracks().forEach((track) => track.stop());

    _localStream = screenSharing
        ? await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': true})
        : await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});

    _localRenderer.srcObject = _localStream;

    var videoTrack = _localStream!.getVideoTracks()[0];
    var sender = _peerConnection!.senders.firstWhere((s) => s.track?.kind == 'video');
    await sender.replaceTrack(videoTrack);

    setState(() => _isScreenSharing = screenSharing);
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

    _peerConnection!.onIceCandidate = (event) {
      if (event.candidate != null) {
        _classroomService.sendIceCandidate(widget.classData['class_id'], {
          'candidate': event.candidate!.candidate,
          'sdpMid': event.candidate!.sdpMid,
          'sdpMLineIndex': event.candidate!.sdpMLineIndex,
        });
      }
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
        actions: [
          if (_isBroadcasting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Video/Whiteboard View
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isBroadcasting
                  ? Stack(
                      children: [
                        RTCVideoView(_localRenderer, mirror: !_isScreenSharing),
                        if (_isWhiteboardActive)
                          WhiteboardWidget(
                            socket: _classroomService.socket,
                            classId: widget.classData['class_id'],
                            isTeacher: true,
                          ),
                      ],
                    )
                  : const Center(
                      child: Text('البث متوقف', style: TextStyle(color: Colors.white)),
                    ),
            ),
          ),
          // Chat View
          Expanded(
            flex: 1,
            child: _buildChatView(),
          ),
          // Status Bar
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Text('حالة الخادم: $_serverMessage'),
          ),
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  String? _extractUrl(String message) {
    final regex = RegExp(r'(uploads/recordings/.*)');
    final match = regex.firstMatch(message);
    return match != null ? 'http://10.0.2.2:3000/${match.group(1)}' : null;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
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
              if (msg.isSystemMessage && msg.recordingUrl != null) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('New Recording Available'),
                    subtitle: const Text('A new session recording is ready for download.'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _launchUrl(msg.recordingUrl!),
                    ),
                  ),
                );
              }
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
            _isBroadcasting ? Icons.videocam_off : Icons.videocam,
            _isBroadcasting ? 'إيقاف البث' : 'بدء البث',
            _toggleBroadcast,
          ),
          _buildControlButton(
            _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            _isScreenSharing ? 'إيقاف المشاركة' : 'مشاركة الشاشة',
            _toggleScreenShare,
            isActive: _isBroadcasting,
          ),
          _buildControlButton(
            Icons.edit,
            _isWhiteboardActive ? 'إخفاء السبورة' : 'عرض السبورة',
            _toggleWhiteboard,
            isActive: _isBroadcasting,
          ),
          _buildControlButton(
            Icons.pan_tool,
            'طلبات المداخلة (${_speakRequests.length})',
            _showSpeakRequests,
            isActive: true,
          ),
          _buildControlButton(
            Icons.people,
            'الحضور (${_presentStudentIds.length}/${_allStudents.length})',
            _showAttendance,
            isActive: true,
          ),
          _buildControlButton(
            _isRecording ? Icons.stop_circle : Icons.radio_button_checked,
            _isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل',
            _toggleRecording,
            isActive: _isBroadcasting,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed, {bool isActive = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: isActive ? onPressed : null,
          iconSize: 30,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey,
        ),
        Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
      ],
    );
  }
}
