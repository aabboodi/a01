import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';
import 'package:frontend/features/auth/application/services/chat_service.dart';
import 'package:frontend/features/classroom/application/services/mediasoup_client_service.dart';
import 'package:frontend/features/classroom/presentation/widgets/whiteboard_widget.dart';
import 'package:frontend/features/classroom/presentation/screens/video_player_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/features/chat/data/chat_repository.dart';
import 'package:frontend/core/constants/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Data model for ChatMessage (assuming it's defined elsewhere or here)
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
  final MediasoupClientService _mediasoupClientService = MediasoupClientService();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  String _serverMessage = '';
  bool _requestSent = false;
  bool _isWhiteboardVisible = true;
  String? _userId;
  bool _isFreeMicMode = false;
  bool _isMicActive = false;
  MediaStream? _localAudioStream;
  bool _isPaused = false;
  ConnectionState _connectionState = ConnectionState.none;

  final ApiChatService _apiChatService = ApiChatService();
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  final ChatRepository _chatRepository = ChatRepository();

  Future<void> _loadChatHistory() async {
    _chatRepository.getMessages(widget.classData['class_id']).listen((history) {
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

      if (mounted) {
        setState(() {
          _chatMessages.clear(); // Clear existing to avoid duplicates when stream updates
          _chatMessages.addAll(historicalMessages);
        });
        _scrollToBottom();
      }
    });
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
            ));
          });
          _scrollToBottom();
        }
      },
      onRequestToSpeakReceived: (data) {},
      onPermissionToSpeakReceived: (data) {
        print("Permission to speak received!");
        _startAudioBroadcast();
      },
      onAudioModeChanged: (data) {
        if (mounted) {
          setState(() {
            _isFreeMicMode = data['isFreeMicMode'];
            if (!_isFreeMicMode && _isMicActive) {
              _toggleMic();
            }
          });
        }
      },
      onSessionStateChanged: (data) {
        if (mounted) {
          setState(() {
            _isPaused = data['isPaused'];
          });
        }
      },
      onUserJoined: (data) {},
      onUserLeft: (data) {},
      onCurrentAttendanceReceived: (data) {},
    );
    _classroomService.connectAndJoin(
      widget.classData['class_id'],
      widget.userData['user_id'],
      widget.userData['full_name'],
    );

    _mediasoupClientService.initialize(widget.classData['class_id'], _classroomService.socket);

    _classroomService.socket.on('new-producer', (data) {
      _startMediasoupConsumer(data['producerId']);
    });

    _classroomService.socket.on('connect', (_) => setState(() => _connectionState = ConnectionState.active));
    _classroomService.socket.on('connecting', (_) => setState(() => _connectionState = ConnectionState.waiting));
    _classroomService.socket.on('disconnect', (_) => setState(() => _connectionState = ConnectionState.none));
  }

  Future<void> _startMediasoupConsumer(String producerId) async {
    try {
      await _mediasoupClientService.createRecvTransport(
        _classroomService.socket,
        widget.classData['class_id'],
      );

      _mediasoupClientService.recvTransport!.on('newconsumer', (consumer) async {
        if (consumer.track != null) {
          final stream = await createLocalMediaStream('media-stream-id');
          stream.addTrack(consumer.track!);
          _remoteRenderer.srcObject = stream;
        }
      });

      await _mediasoupClientService.consume(
        socket: _classroomService.socket,
        transport: _mediasoupClientService.recvTransport!,
        producerId: producerId,
        rtpCapabilities: _mediasoupClientService.device.rtpCapabilities,
        peerId: producerId,
      );
    } catch (e) {
      print('Error starting mediasoup consumer: $e');
    }
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _localAudioStream?.getTracks().forEach((track) => track.stop());
    _classroomService.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty && _userId != null) {
      _classroomService.sendChatMessage(widget.classData['class_id'], message, userId: _userId!);
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
      widget.userData['user_id'].toString(),
      widget.userData['full_name'],
    );
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب المداخلة بنجاح.')),
    );
  }

  Future<bool> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      return false;
    }
    return true;
  }

  Future<void> _startAudioBroadcast() async {
    final hasPermissions = await _requestPermissions();
    if(!hasPermissions){
      return;
    }
    if (_mediasoupClientService.sendTransport == null) {
      await _mediasoupClientService.createSendTransport(
          _classroomService.socket, widget.classData['class_id']);
    }

    try {
      _localAudioStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      final audioTrack = _localAudioStream!.getAudioTracks().first;
      await _mediasoupClientService.produce(
        socket: _classroomService.socket,
        transport: _mediasoupClientService.sendTransport!,
        track: audioTrack,
        stream: _localAudioStream!,
        source: 'mic',
      );
      setState(() => _isMicActive = true);
    } catch (e) {
      print("Error starting student mic: $e");
    }
  }

  Future<void> _toggleMic() async {
    if (_isMicActive) {
      _localAudioStream?.getTracks().forEach((track) => track.stop());
      setState(() => _isMicActive = false);
    } else {
      await _startAudioBroadcast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'تواصل عبر واتساب',
            onPressed: _openWhatsApp,
          ),
          _buildConnectionIndicator(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RTCVideoView(_remoteRenderer, mirror: false),
                  if (_isWhiteboardVisible)
                    WhiteboardWidget(
                      socket: _classroomService.socket,
                      classId: widget.classData['class_id'],
                      isTeacher: false,
                    ),
                  if (_isPaused)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pause_circle_filled, color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'تم إيقاف الجلسة مؤقتاً',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_connectionState != ConnectionState.active)
                    Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              "جاري الاتصال...",
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildChatView(),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: AppTheme.beige,
            child: Text('حالة الخادم: $_serverMessage', style: TextStyle(color: AppTheme.textDark)),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    IconData icon;
    Color color;
    switch (_connectionState) {
      case ConnectionState.active:
        icon = Icons.wifi;
        color = Colors.green;
        break;
      case ConnectionState.waiting:
        icon = Icons.wifi_off;
        color = Colors.orange;
        break;
      default:
        icon = Icons.perm_scan_wifi_outlined;
        color = Colors.red;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(icon, color: color),
    );
  }

  String? _extractUrl(String message) {
    final regex = RegExp(r'(uploads/recordings/.*)');
    final match = regex.firstMatch(message);
    return match != null ? 'http://10.0.2.2:3000/${match.group(1)}' : null;
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
                      icon: const Icon(Icons.play_circle_fill),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(videoUrl: msg.recordingUrl!),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
              return ListTile(
                title: Text(msg.authorName, style: TextStyle(fontWeight: FontWeight.bold, color: msg.isLocal ? AppTheme.forestGreen : Colors.black)),
                subtitle: Text(msg.message),
                tileColor: msg.isLocal ? AppTheme.forestGreen.withOpacity(0.1) : null,
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
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_isFreeMicMode)
            _buildControlButton(
              _isMicActive ? Icons.mic_off : Icons.mic,
              _isMicActive ? 'إيقاف المايك' : 'تفعيل المايك',
              _toggleMic,
            )
          else
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

  Future<void> _openWhatsApp() async {
    // Replace with actual support number
    const phoneNumber = '+966500000000'; 
    const message = 'مرحباً، أحتاج مساعدة في الفصل الدراسي.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح واتساب')),
      );
    }
  }
}
